#!/usr/bin/env python3
#
# Copyright 2022 Justin Cook
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# This bit of code either uses conntrack and counts ESTABLISHED TCP connections
# or failing that reads established connections and samples several times per
# second maintaining count. It listens on the specified port for Prometheus
# scrapes.
#
# References:
# https://projectcalico.docs.tigera.io/reference/host-endpoints/conntrack
# https://learnk8s.io/kubernetes-network-packets
# https://stackabuse.com/serving-files-with-pythons-simplehttpserver-module/
# https://elixir.bootlin.com/linux/v5.17/source/include/net/tcp_states.h
#
# Author: Justin Cook

import http.server
from signal import signal, SIGINT
from subprocess import Popen, PIPE, CalledProcessError
from threading import Thread, Lock
from socketserver import TCPServer
from sys import argv, stderr, exit
from queue import Queue, Empty
from os import _exit, stat
from time import sleep

num_connections = 0
state = 'running'
watch_port = 8080

existing_conns = []
discover_conns = Queue()
conns_lock = Lock()

class PrometheusServiceExporter(http.server.SimpleHTTPRequestHandler):
    """A simple HTTP server that serves metrics for scraping by Prometheus."""
    
    metrics = (
      "# HELP boutique_tcp_established_connections_total A count of "
      "ESTABLISHED TCP connections\n"
      "# TYPE boutique_tcp_established_connections_total counter\n"
      "boutique_tcp_port_established_connections_total {}\n"
    )
    protocol_version = 'HTTP/1.1'

    def do_GET(self):
        if self.path == '/metrics':
            global num_connections, metrics
            payload = bytes(self.metrics.format(num_connections),
                            "utf8")
            self.send_response(200)
            self.send_header("Content-Length", len(payload))
            self.send_header("Connection", "close")
            self.end_headers()
            self.wfile.write(payload)
        else:
            self.send_response(404)
            self.send_header("Connection", "close")
            self.end_headers()

def conntrack_events():
    """Use conntrack for watching ESTABLISHED TCP connections on watch_port.

    This requires root privileges and will raise CalledProcessError if the
    correct privileges are not available.
    """
    global num_connections, watch_port, state
    try:
        subp = Popen(['conntrack', '-E', '-p', 'tcp', '--dport',
                      str(watch_port), '--state', 'ESTABLISHED'], stdout=PIPE)
        sleep(.2)
        if subp.poll():
            raise CalledProcessError(subp.returncode, "conntrack", None)
        while True:
            connection = subp.stdout.readline().decode('utf8')
            if connection: 
                num_connections += 1
    except (CalledProcessError, FileNotFoundError) as err:
        print(err)
        state = 'stopped'
        exit(1)

def get_conns():
    """Open /proc/net/tcp, look for ESTABLISHED TCP connections, and inspect
    the local port of each. If it is the one we are looking for, add it to the
    queue for sorting and counting.
    """
    global num_connections, watch_port, state, discover_conns
    print("get_conns: starting")
    while True:
        try:
            if state != 'running': break
            with open('/proc/net/tcp', 'r') as f:
                conns_lock.acquire()
                while f:
                    line = f.readline()
                    if line == "": break
                    chunkedline = line.split()
                    # Element three is connection state and '01' is
                    # ESTABLISHED.
                    if chunkedline[3] == '01':
                        # chunkedline[1] is the local port, and if it's the one
                        # we are looking for it's ESTABLISHED and needs to be
                        # counted if not already existing.
                        found_port = int(chunkedline[1].split(':')[1], 16)
                        if found_port == watch_port:
                            discover_conns.put_nowait(chunkedline[2])
                conns_lock.release()
                sleep(.033)
        except FileNotFoundError as err:
            print(err, file=stderr)
            _exit(2)

def count_conns():
    global existing_conns, discover_conns, num_connections, state
    print("count_conns: starting")
    while True:
        if state != 'running': break
        conns_lock.acquire()
        try:
            conns = [discover_conns.get() for i in range(discover_conns.qsize())]
        except Empty:
            conns_lock.release()
            continue
        for conn in existing_conns:
            if conn not in conns:
                existing_conns.remove(conn)
        for conn in conns:
            if conn not in existing_conns:
                num_connections += 1
                existing_conns.append(conn)
        conns_lock.release()
        sleep(1)

def cleanup(*args):
    """A simple cleanup function that changes global state and exits as
    necessary.
    """
    global state
    state = 'shutdown'
    raise Exception("Exiting...")

def usage():
    return (
        "usage: tcp_exporter.py <LISTEN_PORT> <WATCH_PORT>\n\n"
        "example: tcp_exporter.py 9100 8080")

def main():
    global watch_port, state
    threads = []

    # Since we're looping and catching Exception, we need to handle SIGINT
    # as a special case.
    signal(SIGINT, cleanup)
    try:
        listen_port = int(argv[1])
        watch_port = int(argv[2])
    except IndexError as err:
        print(usage(), file=stderr)
        exit(1)
        
    # Try and start conntrack, wait, and then check state
    port_discover = Thread(name='conntrack-events-daemon', 
                           target=conntrack_events)
    port_discover.setDaemon(True)
    port_discover.start()
    sleep(.5)

    # If state is 'stopped' then back off and try sampling
    if state != 'running':
        port_discover.join()
        state = 'running'
        # Create a thread that will scrape existing tcp connections and place
        # matching connections on a queue for counting.
        port_discover = Thread(name='port-discover-daemon', 
                            target=get_conns)
        port_discover.setDaemon(True)
        port_discover.start()
        threads.append(port_discover)

        # Create a thread that will count the queue.
        port_counter = Thread(name='port-counter-daemon', 
                            target=count_conns)
        port_counter.setDaemon(True)
        port_counter.start()
        threads.append(port_counter)

    # A mini HTTP server to make metrics available for scraping
    handler = PrometheusServiceExporter
    try:
        TCPServer.allow_reuse_address = True
        with TCPServer(("", listen_port), handler) as httpd:
            print("Server started at localhost: {}".format(listen_port))
            try:
                httpd.serve_forever()
            except Exception as err:
                print(err, file=stderr)
            finally:
                httpd.server_close()
                httpd.shutdown()
    except OSError as err:
        print(err)
        exit(4)

    [thread.join() for thread in threads]

if __name__ == "__main__":
    main()