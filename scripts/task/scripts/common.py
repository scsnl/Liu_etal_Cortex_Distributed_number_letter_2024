#common.py
from psychopy import visual, event, gui
import os, pickle

background_color = "#000000"
text_color = (-1, 1, -1)
text_height = 48
screen_size = [1024, 768]

def get_config():
    if os.path.exists('config.pck'):
        f = open('config.pck', 'r')
        info = pickle.load(f)
        f.close()
        return info    
    else:
        return None

class clickBox:
	def __init__(self, pos=[0,0], width=0, height=0):
		x0 = pos[0] - (width/2)
		x1 = pos[0] + (width/2)

		y0 = pos[1] - (height/2)
		y1 = pos[1] + (height/2)

		self.x0 = x0
		self.x1 = x1
		self.y0 = y0
		self.y1 = y1
		self.corners = [x0, y0, x1, y1]
		print self.corners

	def inBox(self, x, y):
		xpass = False
		ypass = False
		if x >= self.x0 and x <= self.x1:
			xpass = True
		if y >= self.y0 and y <= self.y1:
			ypass = True

		if xpass and ypass:
			return True
		else:
			return False

class Message:
	def __init__(self, win, text='', height=24, pos=[0,0], color=(1, 1, 1)):
		self.txt = visual.TextStim(win, text, height=height, pos=pos, color=color, alignHoriz='center', wrapWidth=win.size[0] - 50, font='Courier New', bold=True)
		self.win = win

	def send(self, txt, wait=False):
		print txt
		#if wait == True:
			#txt += "\nPress a key to continue."
		self.txt.setText(txt)
		self.txt.draw()
		self.win.flip()
		if wait	== True:
			event.waitKeys()

	def draw(self):
		self.txt.draw()

class MessageImg:
	def __init__(self, win, img=None, pos=[0,0]):
		self.img = visual.ImageStim(win, img, pos=pos)
		self.win = win

	def send(self, img, wait = False):
		self.img.setImage(img)
		self.img.draw()
		self.win.flip()
		if wait == True:
			event.waitKeys()


def infoGUI(info = {}):
	default_info = {'Subject':777, 'Session':1}

	order = ['Subject', 'Session']

	#merge the default list with what is provided by the user
	for key in info.keys():
		#if this is a new key, add it to the order list
		if not default_info.has_key(key):
			order.append(key)

		default_info[key] = info[key]

	GUI = gui.Dlg(title='SMP Followup')
	GUI.SetSize([1000, 1000])
	for key in order:
		value = default_info[key]
		if type(value) == list:
			GUI.addField(key,choices=value)
		else:
			GUI.addField(key,value)

	GUI.show()

	if GUI.OK:
		info = {}
		for key, value in zip(order, GUI.data):
			info[key] = value
		return info
	else:
		abort = gui.Dlg(title = 'Quitting...')
		abort.addText('Experiment Aborted by User')
		abort.show()
		raise Exception("Experiment Aborted by User")
