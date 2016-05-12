echo "set ENV container address"
export CONTAINER_ADDRESS="$(ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}' | grep 192.168.0):3000" 
echo "printing CONTAINER_ADDRESS:"
printenv CONTAINER_ADDRESS
echo "set permanent ENV container address"
echo  "export CONTAINER_ADDRESS=\"$(ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}' | grep 192.168.0 ):3000\"" >> ~/.bashrc
