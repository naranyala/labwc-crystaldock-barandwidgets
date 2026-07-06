#!/usr/bin/env python3
import sys
import xml.etree.ElementTree as ET
import os

CONFIG_FILE = os.path.expanduser('~/.config/labwc/rc.xml')

def get_keybind(action_cmd):
    try:
        tree = ET.parse(CONFIG_FILE)
        root = tree.getroot()
        for kb in root.findall('.//keybind'):
            cmd_elem = kb.find('.//command')
            if cmd_elem is not None and cmd_elem.text == action_cmd:
                print(kb.get('key'))
                return
        print("")
    except:
        print("")

def set_keybind(action_cmd, new_key):
    try:
        tree = ET.parse(CONFIG_FILE)
        root = tree.getroot()
        # Find existing
        for kb in root.findall('.//keybind'):
            cmd_elem = kb.find('.//command')
            if cmd_elem is not None and cmd_elem.text == action_cmd:
                kb.set('key', new_key)
                tree.write(CONFIG_FILE)
                os.system('labwc -r')
                return
        
        # If not found, add it
        keyboard = root.find('.//keyboard')
        if keyboard is not None:
            kb = ET.SubElement(keyboard, 'keybind', {'key': new_key})
            action = ET.SubElement(kb, 'action', {'name': 'Execute'})
            cmd = ET.SubElement(action, 'command')
            cmd.text = action_cmd
            tree.write(CONFIG_FILE)
            os.system('labwc -r')
    except Exception as e:
        print(e)

if len(sys.argv) < 3:
    sys.exit(1)

if sys.argv[1] == 'get':
    get_keybind(sys.argv[2])
elif sys.argv[1] == 'set' and len(sys.argv) == 4:
    set_keybind(sys.argv[2], sys.argv[3])
