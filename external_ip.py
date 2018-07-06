#!/usr/bin/env python3
from requests import get
import smtplib
"""
v1.0
Currently designed for python3 and Linux
This script is designed to email your
external ip address if it changes. To
use this script input your email
infomation in to the 'sending_email', 'password',
'mail_server', 'mail_server_port' and 'delivery_email' variables.
The print() statements commented out are for
testing it in a terminal. Simply uncomment them
to double check it works with your system. Add this
script to your scheduled events and you won't
need to buy a static ip.

For help setting up email refer to:
https://automatetheboringstuff.com/chapter16/


Written by NunchuckFusion
Email: NunchuckFusion@gmail.com

example:
sending_email='badgerlover18@gmail.com'
password='supersecretwords'
delivery_email='iwannknowips@gmail.com'
mail_server='smtp.gmail.com'
mail_server_port=587

"""

sending_email= ''
password=''
delivery_email=''
mail_server='smtp.gmail.com'
mail_server_port=587

ip = get('https://api.ipify.org').text
#print('My public IP address is: {}'.format(ip))
try:
    iplog= open("/var/tmp/external_ip.log", 'r')

except FileNotFoundError:
    iplog= open("/var/tmp/external_ip.log", 'w')
    iplog.close()
    pass
iplog= open("/var/tmp/external_ip.log", 'r')
currentip=iplog.read()
currentip=currentip.strip("\n")
if ip != currentip:
    #print("Mismatch")
    iplog.close()
    iplog= open("/var/tmp/external_ip.log", 'w')
    iplog.write(ip)
    iplog.close()
    mail = smtplib.SMTP(mail_server, mail_server_port)
    mail.ehlo()
    mail.starttls()
    mail.login(sending_email, password)
    mail.sendmail(sending_email, delivery_email, 'Subject: IP Address \nNew IP is {}'.format(ip))
    mail.quit()
    quit()
elif ip == currentip:
    #print("Match")
    quit()
else:
    #print("Error")
    quit()
iplog.close()
