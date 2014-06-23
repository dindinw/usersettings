rm mybox mybox.pub
ssh-keygen -b 2048 -t rsa -C "mybox insecure public key" -f .mybox -q -N ""
cat ./mybox
cat ./mybox.pub