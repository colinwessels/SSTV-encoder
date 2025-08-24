The script main2.m will take in a jpeg image (ideally 240 by 320) and encode it using the Scottie 1 mode for SSTV (slow-scan television). It includes a header to indicated the SSTV mode. The output of this script (a wav file) can be processed by a SSTV decoder to generate the image file back.

The script longer.m has a longer run time, but the output is smoother at the ends of each line where the frequency of the output signal abruptly changes. If one decodes the audio, the image should have less distortion.

Main1.m shows some of my struggles with this project. There are large jumps in the output signal frequency between each pixel, whether the color is different or the same. This was my initial effort for encoding the images.


This work is covered by the GNU General Public V3.0 License.
