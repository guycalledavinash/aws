# This command repeatedly checks the headers of a web server by making HTTP requests to a URL and counting how many times the -server header appears in the response.

while true; do 
  curl -sL https://failover.avinash.fun | grep -i '\-server'; 
  sleep 1; 
  echo "The count is $I"; 
  sleep 1; 
  I=$(( $I + 1 )); 
done
