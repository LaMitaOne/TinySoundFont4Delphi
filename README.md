# 🎹 TinySoundFont4Delphi  v0.2     
A complete, high-performance Delphi wrapper for Bernhard Schelling's TinySoundFont (v0.9) library.    
     
TinySoundFont is a software synthesizer for playing SoundFont2 (.sf2) files. This repository provides everything you need to integrate it into a Delphi (VCL/FMX) application, including a fully functional, threaded, double-buffered demo project.        
      
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/LaMitaOne/Tinysoundfont4delphi)    
     
🚀 Features of this Wrapper & Demo    
     
    Complete API Mapping: Fully exposes all tsf_ functions, including channel-based preset and note control.
    Threaded Audio Synthesizing: No UI freezes! The demo uses a background TThread combined with TStopwatch (QPC) to pump audio data without blocking the main form.
    Cracke-free Double Buffering: Implements a Ping-Pong audio buffer system via MMSystem (waveOut) to ensure seamless, high-quality 32-bit float audio playback.
    Built-in Sequencer: The demo includes an 8-bit style melody sequencer, showing how to trigger MIDI notes dynamically over time.
    Ready for VCL & FMX: The wrapper unit is pure Object Pascal, ready for any Delphi framework.
    Sample includes 8bitsf.SF2
      
📦 Repository Contents     
      
    TinySoundFont.pas: The complete Delphi wrapper unit. It dynamically loads the TinySoundFont DLL and exposes all available functions (loading, rendering, channel control, etc.).
    Unit1.pas / Unit1.dfm: A fully functional sample project. It demonstrates how to initialize the wrapper, load a .sf2 file, and play a melody directly through the Windows sound card using a high-precision audio thread.
    compileDLL/: Contains the necessary instructions and C-source setup to compile the required tinysoundfont.dll.
      
🛠️ Requirements      
      
    Delphi 10.x, 11.x, or 12.x (RAD Studio). The project is configured for the x64 (64-bit) platform.
    A valid SoundFont2 (.sf2) file.
      
⚙️ How to Compile the DLL     
     
The Delphi wrapper requires a compiled tinysoundfont.dll. A pre-compiled 64-bit DLL is included in the sample folder, but you can compile it yourself using Microsoft Visual Studio.      
     
    Download the original tsf.h header file from the official TinySoundFont repository.
    Open the x64 Native Tools Command Prompt for VS 2022 (or 2019) from your Windows Start Menu.
    Navigate to the compileDLL folder in this repository.
    Compile the DLL using the provided C-file and the following command:
    
    cl /O2 /LD tinysoundfont.c
      
(Note: The C code in the compileDLL folder uses __declspec(dllexport) and prefixes all functions with dll_tsf_ to ensure clean, compatible exports for Delphi).
▶️ How to Run the Demo      
      
    Open the project in Delphi, select the 64-bit Windows target platform, and compile it.
    Ensure tinysoundfont.dll is in the same folder as the generated .exe.
    Run the application.
    Click "Init Audio" to load the DLL and initialize the Windows sound card.
    Click "Load Soundfont" and select any .sf2 file on your computer.
    Click "Play" to start the sequencer. You will hear the 8-bit style melody through your speakers, perfectly timed!
      
Looking for free SoundFonts? You can find great ones here: https://www.zanderjaz.com/downloads/soundfonts/     
      
📄 License    
This wrapper and demo code is provided under the MIT License. The underlying TinySoundFont library by Bernhard Schelling is also MIT Licensed.     
