bin2hex %1 hex_file.txt
copy /B "tool\hex-desc.txt"+"hex_file.txt" %2
del hex_file.txt
