# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
(Not anymore lol) -- Audrey
"""
import mediapipe as mp
import cv2
import numpy as np
import uuid
import os
import time
import csv
from datetime import date
from datetime import datetime
import pandas as pd


#now = datetime.now()
#n = now.strftime('%y-%m-%d_%H-%M-%S.%f')[:-3]
#csv_name = "mediapipe_"+n+".csv"
#pd.DataFrame({}).to_csv(csv_name)

mp_drawing = mp.solutions.drawing_utils
mp_hands = mp.solutions.hands

"""
Right now, you can use 0 as the parameter as long as your default camera is not occupied
However, if that changes, use these lines of codes instead.

E.g. if you want to use defalt camera
cap = cv2.VideoCapture(0)

E.g. if you want to use camera no.2
index = 2 + cv2.CAP_MSMF
cap = cv2.VideoCapture(index)

Remember, you have to change all occurrences of this line! --Audrey
"""

#modification made for Brian's Laptop
index = 1 + cv2.CAP_MSMF
cap = cv2.VideoCapture(index)

if(cap.isOpened()):
    print("open")
else:
    print("not open")
with mp_hands.Hands(min_detection_confidence=0.8, min_tracking_confidence=0.5) as hands: 
    while cap.isOpened():
        ret, frame = cap.read()
        
        # BGR 2 RGB
        image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Flip on horizontal
        image = cv2.flip(image, 1)
        
        # Set flag
        image.flags.writeable = False
        
        # Detections
        results = hands.process(image)
        
        # Set flag to true
        image.flags.writeable = True
        
        # RGB 2 BGR
        image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)
        
        # Detections
        print(results)
        
        # Rendering results
        if results.multi_hand_landmarks:
            for num, hand in enumerate(results.multi_hand_landmarks):
                mp_drawing.draw_landmarks(image, hand, mp_hands.HAND_CONNECTIONS, 
                                        mp_drawing.DrawingSpec(color=(121, 22, 76), thickness=2, circle_radius=4),
                                        mp_drawing.DrawingSpec(color=(250, 44, 250), thickness=2, circle_radius=2),
                                         )
            
        
        cv2.imshow('Hand Tracking', image)

        if cv2.waitKey(10) & 0xFF == ord('q'):
            break

cap.release()
cv2.destroyAllWindows()

#mp_drawing.DrawingSpec??

#os.mkdir('Output Images')

#modification made for Brian's Laptop
index = 1+ cv2.CAP_MSMF
cap = cv2.VideoCapture(index)

with mp_hands.Hands(min_detection_confidence=0.8, min_tracking_confidence=0.5) as hands: 
    while cap.isOpened():
        ret, frame = cap.read()
        
        # BGR 2 RGB
        image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Flip on horizontal
        image = cv2.flip(image, 1)
        
        # Set flag
        image.flags.writeable = False
        
        # Detections
        results = hands.process(image)
        
        # Set flag to true
        image.flags.writeable = True
        
        # RGB 2 BGR
        image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)
        
        # Detections
        print(results)
        
        # Rendering results
        if results.multi_hand_landmarks:
            for num, hand in enumerate(results.multi_hand_landmarks):
                mp_drawing.draw_landmarks(image, hand, mp_hands.HAND_CONNECTIONS, 
                                        mp_drawing.DrawingSpec(color=(121, 22, 76), thickness=2, circle_radius=4),
                                        mp_drawing.DrawingSpec(color=(250, 44, 250), thickness=2, circle_radius=2),
                                         )
            
        # Save our image    
        #cv2.imwrite(os.path.join('Output Images', '{}.jpg'.format(uuid.uuid1())), image)
        cv2.imshow('Hand Tracking', image)

        if cv2.waitKey(10) & 0xFF == ord('q'):
            break

cap.release()
cv2.destroyAllWindows()

#print(mp_hands.HandLandmark.WRIST)
#print(results.multi_hand_landmarks[1])
#print(results.multi_handedness[0].classification[0].index == num)
round(results.multi_handedness[0].classification[0].score, 2)
def get_label(index, hand, results):
    output = None
    for idx, classification in enumerate(results.multi_handedness):
        if classification.classification[0].index == index:
            
            # Process results
            label = classification.classification[0].label
            score = classification.classification[0].score
            text = '{} {}'.format(label, round(score, 2))
            
            # Extract Coordinates
            coords = tuple(np.multiply(
                np.array((hand.landmark[mp_hands.HandLandmark.WRIST].x, hand.landmark[mp_hands.HandLandmark.WRIST].y)),
            [640,480]).astype(int))
            
            output = text, coords
            
    return output

get_label(num, hand, results)

#modification made for Brian's Laptop
index = 1 + cv2.CAP_MSMF
cap = cv2.VideoCapture(index)

with mp_hands.Hands(min_detection_confidence=0.8, min_tracking_confidence=0.5) as hands: 
    while cap.isOpened():
        ret, frame = cap.read()
        
        # BGR 2 RGB
        image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Flip on horizontal
        image = cv2.flip(image, 1)
        
        # Set flag
        image.flags.writeable = False
        
        # Detections
        results = hands.process(image)
        
        # Set flag to true
        image.flags.writeable = True
        
        # RGB 2 BGR
        image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)
        
        # Detections
        print(results)
        
        # Rendering results
        if results.multi_hand_landmarks:
            for num, hand in enumerate(results.multi_hand_landmarks):
                mp_drawing.draw_landmarks(image, hand, mp_hands.HAND_CONNECTIONS, 
                                        mp_drawing.DrawingSpec(color=(121, 22, 76), thickness=2, circle_radius=4),
                                        mp_drawing.DrawingSpec(color=(250, 44, 250), thickness=2, circle_radius=2),
                                         )
                
                # Render left or right detection
                if get_label(num, hand, results):
                    text, coord = get_label(num, hand, results)
                    cv2.putText(image, text, coord, cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2, cv2.LINE_AA)
            
        # Save our image    
        #cv2.imwrite(os.path.join('Output Images', '{}.jpg'.format(uuid.uuid1())), image)
        cv2.imshow('Hand Tracking', image)

        if cv2.waitKey(10) & 0xFF == ord('q'):
            break

cap.release()
cv2.destroyAllWindows()

from matplotlib import pyplot as plt

header = ['timestamp', 'thumb', 'index', 'middle', 'ring', 'little']
data = []

'''
Modify this joint list to add/delete joint angle choices
'''
joint_list = [[4,2,0], [8,5,0], [12,9,0], [16,13,0], [20,17,0]]
#joint_list[3]
def draw_finger_angles(image, results, joint_list):
    
    # Loop through hands
    for hand in results.multi_hand_landmarks:
        #Loop through joint sets 
        angles = []
        pos = []
        for joint in joint_list:
            a = np.array([hand.landmark[joint[0]].x, hand.landmark[joint[0]].y]) # First coord
            b = np.array([hand.landmark[joint[1]].x, hand.landmark[joint[1]].y]) # Second coord
            c = np.array([hand.landmark[joint[2]].x, hand.landmark[joint[2]].y]) # Third coord
            pos.append([a, b, c])
    
        now = datetime.now()
        n = now.strftime('%y/%m/%d %H:%M:%S.%f')[:-3]
        
        for p in pos:
            a = p[0]
            b = p[1]
            c = p[2]
        
            radians = np.arctan2(c[1] - b[1], c[0]-b[0]) - np.arctan2(a[1]-b[1], a[0]-b[0])
            angle = np.abs(radians*180.0/np.pi)
            
            if angle > 180.0:
                angle = 360-angle
                
            cv2.putText(image, str(round(angle, 2)), tuple(np.multiply(b, [640, 480]).astype(int)),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 2, cv2.LINE_AA)
            #t = time.localtime()
            #current_time = time.strftime("%H:%M:%S", t)
            #today = date.today()
            #d = today.strftime("%m/%d/%y")
            """
            No you don't need hand landmark data --Audrey
            """
            #print("hand landamark data starts")
            #print(hand)
            #print("hand landamark data ends")
            #tempdata.append(joint)
            angles.append(angle)
            
        tempdata = []
        tempdata.append(n)
        for angle in angles:
            tempdata.append(angle)
        data.append(tempdata)
        print(tempdata)
    return image
results.multi_hand_landmarks
test_image = draw_finger_angles(image, results, joint_list)

#modification made for Brian's Laptop
index = 1 + cv2.CAP_MSMF
cap = cv2.VideoCapture(index)

now = datetime.now()
n = now.strftime('%y-%m-%d_%H-%M-%S.%f')[:-3]
new_name = "mediapipe_"+n+".csv"
pd.DataFrame({}).to_csv(new_name)

with mp_hands.Hands(min_detection_confidence=0.8, min_tracking_confidence=0.5) as hands: 
    while cap.isOpened():
        ret, frame = cap.read()
        
        # BGR 2 RGB
        image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Flip on horizontal
        image = cv2.flip(image, 1)
        
        # Set flag
        image.flags.writeable = False
        
        # Detections
        results = hands.process(image)
        
        # Set flag to true
        image.flags.writeable = True
        
        # RGB 2 BGR
        image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)
        
        # Detections
        print(results)
        
        # Rendering results
        if results.multi_hand_landmarks:
            for num, hand in enumerate(results.multi_hand_landmarks):
                mp_drawing.draw_landmarks(image, hand, mp_hands.HAND_CONNECTIONS, 
                                        mp_drawing.DrawingSpec(color=(121, 22, 76), thickness=2, circle_radius=4),
                                        mp_drawing.DrawingSpec(color=(250, 44, 250), thickness=2, circle_radius=2),
                                         )
                
                # Render left or right detection
                if get_label(num, hand, results):
                    text, coord = get_label(num, hand, results)
                    cv2.putText(image, text, coord, cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2, cv2.LINE_AA)
            
            # Draw angles to image from joint list
            draw_finger_angles(image, results, joint_list)
            
        # Save our image    
        #cv2.imwrite(os.path.join('Output Images', '{}.jpg'.format(uuid.uuid1())), image)
        cv2.imshow('Hand Tracking', image)

        

        if cv2.waitKey(10) & 0xFF == ord('q'):
            with open(new_name, mode='r+', encoding='UTF8', newline='') as f:
                writer = csv.writer(f)

                # write the header
                writer.writerow(header)

                # write multiple rows
                writer.writerows(data)
            print(data)
            break

cap.release()
cv2.destroyAllWindows()