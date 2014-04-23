
OpenCV
------


FFmpeg
------

offical site : http://www.ffmpeg.org/index.html

Download
  * Windows : http://ffmpeg.zeranoe.com/builds/win32/static/ffmpeg-latest-win32-static.7z

Usage 

  * DirectShow (https://trac.ffmpeg.org/wiki/DirectShow)

    - list devices:
    
    ```
    ffmpeg -list_devices true -f dshow -i dummy
    ```

    - capture video / audio (in most case, set no options get the best result)
    
    ```
    ffmpeg -f dshow -i video="Integrated Camera" output.mp4

    ffmpeg -f dshow -i video="Integrated Camera":audio="内装麦克风 (Conexant 20672 SmartAudi" -vcodec libx264 -preset ultrafast -tune zerolatency -r 10 -async 1 -acodec libmp3lame -ab 24k -ar 22050 -bsf:v h264_mp4toannexb -maxrate 750k -bufsize 3000k output.mp4

    ffmpeg -f dshow -video_size 1280x720 -framerate 7.5 -pixel_format yuyv422 -i video="Integrated Camera" out.avi 

    ffmpeg -f dshow -video_size 1280x720 -framerate 15 -vcodec mjpeg -i video="Integrated Camera" out.avi 

    ffmpeg -f dshow -i audio="内装麦克风 (Conexant 20672 SmartAudi" -acodec libmp3lame -bufsize 3000k output.mp3
    ```  

    note: the chinese character is supported. but the list command may get a unrecognized chars, may need to find the 
    correct name in registy. or by a tool (http://www.videohelp.com/download/graphedit10-090724.zip)

   - capture disktop (https://trac.ffmpeg.org/wiki/How%20to%20grab%20the%20desktop%20%28screen%29%20with%20FFmpeg)
     need to install 
      * this (https://github.com/rdp/screen-capture-recorder-to-video-windows-free) first.
      * or http://code.google.com/p/ardesia/

     use gdigrab
     ```
     ffmpeg -f gdigrab -i desktop out.mp4
     ffmpeg -f gdigrab -video_size vga -i title=bin out2.mp4
     ```

  * How to do streaming  (https://trac.ffmpeg.org/wiki/StreamingGuide)