#Author Sinan ötük

import pygame
import os

# Set the width and height of the screen
width = 200 
height = width / (16.0 / 9.0)

# Create a Pygame screen to display the video
screen = pygame.display.set_mode((width, height))

ppm_files = []


# Set the list of PPM files to be displayed

for i in range(1,10):
    name = "frames/" + str(i) + ".ppm"
    ppm_files.append(name)    

# Set the framerate of the video
framerate = 30

# Load the first frame
frame = pygame.image.load(ppm_files[0])

# Set a counter for the current frame
frame_counter = 0

# Set a flag to control the main loop
running = True

while running:
    # Increment the frame counter
    frame_counter += 1

    # Check if the end of the list of PPM files has been reached
    if frame_counter >= len(ppm_files):
        # If the end of the list has been reached, set the frame counter back to 0
        frame_counter = 0

    # Load the current frame
    frame = pygame.image.load(ppm_files[frame_counter])

    # Display the current frame on the screen
    screen.blit(frame, (0, 0))
    pygame.display.flip()

    # Set the framerate
    pygame.time.delay(1000 // framerate)

    # Check if the user has closed the window
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

# Quit Pygame
pygame.quit()
