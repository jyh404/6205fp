Hello from Aloysius!
Hello from Jonathan!

After pulling from Github:
- Recall that you can't compile the folder directly since the .git folder interferes with stuff
- So work in local copy and delete ./git folder
- Push back by copy pasting to folder that is linked to Git

2025/05/16
- Sorry Joe -- just began looking at this again
- Previous progress:
-- Formant calculation seemed mostly correct based on UART output
-- We hooked it up to HDMI 
- A reminder: the microphone is hooked up as we did in one of the weekly assignments, which is the upper row of bottommost part (align with 3V3, GND)

There are currently two top_levels, which we separate since (for now) I don't want to think about the HDMI clock and how that interacts with UART:
- top_level.sv pipes formant values (along with FFT values and sound values) via UART to computer. The Python files in ctrl/aloy/ use this data to make spectrogram graphs
- top_level_hdmi.sv pipes formant values into a display via HDMI.

Need to edit xdc/top_level.xdc when you use each one (comment out HDMI/UART otherwise it is unhappy about unassigned ports).