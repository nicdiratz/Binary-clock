# Binary-clock
This Binary clock is a project from software to hardware for a binary counting clock (12h). The first 4 leds are for the hours (blue), the last 6 leds (green) are for the minutes. 
This project consists in one Attiny84 and 2 datashifters to control the leds's behaviour. The precision of the clock is due to a 16Mhz external quarz crystal. 
Another upgrade could be the addition of a 7 digit segment which will tell the seconds. 

The code language is C++ but i'll upgrade it to Assembly (one day). I've programmed the Attiny with an arduino (Mega 2560) setup.

<img width="200" height="165" alt="circuit_image" src="https://github.com/user-attachments/assets/1a000247-19fc-4dea-9ee3-b4e973e06e84" />

The pin's flags are: 

<img width="200" height="150" alt="image" src="https://github.com/user-attachments/assets/121e0860-4ce7-4322-9d9b-924e26955354" />


<img width="141" height="137" alt="image" src="https://github.com/user-attachments/assets/6c85f751-d749-4006-9804-aa7b6cd730fa" />

I used this scheme to have a serial connection between the datashifters:

<img width="168" height="150" alt="immagine" src="https://github.com/user-attachments/assets/5d047097-acbb-4dde-a5cf-96d81a232dc7" />

The final circuit Scheme is this:

<img width="300" height="374" alt="circuit_image(2)" src="https://github.com/user-attachments/assets/660f5fdf-b5c2-4414-99ba-e415e2027c60" />

Breadboard Prototype:
https://youtube.com/shorts/VfcjGmsS2oI?feature=share



## License

This project is source-available and free for personal, educational, and
non-commercial use.

- Firmware is licensed under the PolyForm Noncommercial License 1.0.0
- Hardware designs and documentation are licensed under
  Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International

Commercial use is strictly prohibited without prior written permission.
