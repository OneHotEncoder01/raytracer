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
- CUDA (optional, for GPU-accelerated rendering)

## Getting Started

### Prerequisites

Ensure you have the following libraries installed:

- OpenGL
- GLFW
- OpenMP (optional, for parallel processing)
- CUDA (optional, for GPU-accelerated rendering)

### Compiling the Project

1. Clone the repository:
    ```sh
    git clone https://github.com/OneHotEncoder01/raytracer/
    cd raytracer
    ```

2. Create a `build` directory and navigate to it:
    ```sh
    mkdir build
    cd build
    ```

### Running the Project

1. After compiling, you can run the executable:
    ```sh
    ./cppart
    ```

2. If CUDA drivers are installed, the project will leverage GPU acceleration for rendering. If CUDA is not available, the CPU-based rendering will be used and the output will be saved to a PPM file.

3. To redirect the output to a PPM file, run the executable with the following command:
    ```sh
    ./cppart > output.ppm
    ```

    - On **Linux**, this will save the output image to `output.ppm`.
    - On **Windows**, the same command can be used in a Command Prompt or PowerShell to save the output.

4. When prompted, enter the number of spheres you want to render.

5. Watch as the window displays the ray-traced scene with a rotating camera.

### CUDA Notes

- If you encounter CUDA errors, ensure your CUDA drivers are correctly installed and your GPU architecture is properly set in the Makefile. Check [this guide](https://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards/) for GPU-specific settings.
- Modify the Makefile to match your GPU architecture if necessary.

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
