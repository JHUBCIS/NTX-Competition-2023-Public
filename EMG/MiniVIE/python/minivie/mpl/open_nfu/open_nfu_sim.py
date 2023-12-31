import socket
import threading
import controls


class Simulator(object):

    def __init__(self, local_address=('0.0.0.0', 9027), remote_address=('127.0.0.1', 19028)):
        # Create a simulator that sends percepts and heartbeats.  Data comes from nfu_event_sim.csv file
        print('Starting Simulator')

        self.sim_file = '../tests/nfu_event_sim.csv'

        self.local_address = local_address
        self.remote_address = remote_address
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.bind(local_address)
        self.sock.settimeout(3.0)

        self.stop_event = threading.Event()

        self.thread = threading.Thread(target=self.loop)
        self.thread.name = 'OpenNfuSimulator'

    def start(self):
        self.thread.start()

    def loop(self):
        import csv
        import time

        run = True

        while run:
            print(f'Running Simulator. Sending to {self.remote_address}')
            with open(self.sim_file, 'rt', encoding='ascii') as csv_file:
                rows = csv.reader(csv_file, delimiter=',')
                for row in rows:
                    b = bytearray.fromhex(''.join(row))
                    self.sock.sendto(b, self.remote_address)
                    time.sleep(controls.timestep)
                    if self.stop_event.is_set():
                        run = False
                        break

    def stop(self):
        # stop simulator thread
        print('Stopping Simulator')
        self.stop_event.set()
        self.sock.close()


def test_simulator(duration=10):
    """
    Run simulator for testing.  From command line: (from directory \minivie\python\minivie)
    py -3 -c "from mpl.open_nfu.open_nfu_sim import test_simulator; test_simulator(duration=60)"

    @param duration: number of seconds to run simulator (default = 10 sec)
    @return: None
    """
    import time

    a = Simulator()
    a.start()
    try:
        time.sleep(duration)
    except KeyboardInterrupt:
        pass

    a.stop()
