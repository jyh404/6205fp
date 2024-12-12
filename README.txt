Hello from Aloysius!
Hello from Jonathan!

There are currently two top_levels, which we separate since (for now) I don't want to think about the HDMI clock and how that interacts with UART:
- top_level.sv pipes formant values (along with FFT values and sound values) via UART to computer. The Python files in ctrl/aloy/ use this data to make spectrogram graphs
- top_level_hdmi.sv pipes formant values into a display via HDMI.

Need to edit xdc/top_level.xdc when you use each one (comment out HDMI/UART otherwise it is unhappy about unassigned ports).