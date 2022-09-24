cmake_minimum_required(VERSION 3.23)
project(prototype C)

set(CMAKE_C_STANDARD 17)

add_executable(prototype
        # Main
        main.c main.h

        # Keymatrix
        keymatrix/kmx.c
        keymatrix/kmx.h

        )
