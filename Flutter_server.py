from bluedot.btcomm import BluetoothServer
from signal import pause
import picar_4wd as fc
speed= 50
DIRECTION = "direction is North"
distance = -1
def detect_obstacle():
	global distance
	distance = fc.us.get_distance()
	print(f"Distance to obstacle: {distance} cm")

def rc(data):
	global speed,DIRECTION,distance
	detect_obstacle()
	a = data.split()
	if(a[0]=="A"):
		fc.forward(10)
		DIRECTION = "direction is North"
	elif(a[0]=="B"):
		fc.stop()
		DIRECTION = "Stopped due "+DIRECTION
	elif(a[0]=="C"):
		fc.backward(10)
		DIRECTION = "direction is South"
	elif(a[0]=="D"):
		fc.turn_left(10)
		DIRECTION = "direction is East"
	elif(a[0]=="E"):
		fc.turn_right(10)
		DIRECTION = "direction is West"
	print(data)
	send_data = str(speed) +":"+ DIRECTION +":"+ str(distance)
	s.send(send_data)
s = BluetoothServer(rc)
pause()
