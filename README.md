# Ray Tracing in a Weekend with GLFW

This project is inspired by Peter Shirley's "Ray Tracing in a Weekend" and demonstrates how to render rotating spheres using a ray tracing algorithm with OpenGL and GLFW for visualization.

## Features

- Ray tracing to render realistic images of spheres
- GLFW for creating a window and displaying the rendered images
- User-defined number of spheres
- Rotating camera around the spheres

## Requirements

- C++17
- OpenGL
- GLFW
- OpenMP (optional for parallel rendering)

## Getting Started

### Prerequisites

Ensure you have the following libraries installed:

- OpenGL
- GLFW
- OpenMP (optional, for parallel processing)

### Compiling the Project

1. Clone the repository:
    ```sh
    git clone https://github.com/yourusername/ray-tracing-glfw.git
    cd ray-tracing-glfw
    ```

2. Create a `build` directory and navigate to it:
    ```sh
    mkdir build
    cd build
    ```

3. Compile the project using `CMake`:
    ```sh
    cmake ..
    make
    ```

### Running the Project

1. After compiling, you can run the executable:
    ```sh
    ./RayTracingGLFW
    ```

2. When prompted, enter the number of spheres you want to render.

3. Watch as the window displays the ray-traced scene with a rotating camera.

Beware, even if you have a NVidia GPU your device might have a different structure! This code is tested on my 3060 TI, if you have a different device you might need to change the Architecture flag.
Please refer to https://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards/ if you have a CUDA error. You can simply modify the Makefile with your GPU flag.

## Project Structure

- `main.cc`: Main application file containing the GLFW loop and rendering logic.
- `camera.h` and `camera.cpp`: Camera class for handling ray generation and rendering.
- `rtweekend.h`: Utility functions and constants.
- `hittable.h`, `hittable_list.h`, `material.h`, `sphere.h`: Classes for handling objects in the scene, materials, and ray-sphere intersections.

## Notes

- The project uses OpenMP for parallel rendering. If your system doesn't support OpenMP, you can remove the OpenMP-specific parts from the `camera.cpp` file.
- This project is designed to give a visual demonstration of the concepts explained in "Ray Tracing in a Weekend". For a deeper understanding, please refer to the original book by Peter Shirley.

## Inspiration

This project is heavily inspired by Peter Shirley's "Ray Tracing in a Weekend". The book provides a comprehensive introduction to ray tracing and is highly recommended for anyone interested in computer graphics and rendering.

## License

This project is dedicated to the public domain under the CC0 Public Domain Dedication. For more information, see the `COPYING.txt` file or visit [http://creativecommons.org/publicdomain/zero/1.0/](http://creativecommons.org/publicdomain/zero/1.0/).

## Acknowledgements

- Peter Shirley for the original "Ray Tracing in a Weekend" book and inspiration.
- The GLFW library for window creation and OpenGL context management.
