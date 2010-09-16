set rtp+=webapi-vim

let notification_url = "https://api.cybozulive.com/api/notification/V2"

let config = {}
let configfile = expand('~/.cybozulive')
if filereadable(configfile)
  let config = eval(join(readfile(configfile), ""))
else
  let config.consumer_key = input("consumer_key:")
  let config.consumer_secret = input("consumer_secret:")
  
  let request_token_url = "https://api.cybozulive.com/oauth/initiate"
  let auth_url =  "https://api.cybozulive.com/oauth/authorize"
  let access_token_url = "https://api.cybozulive.com/oauth/token"
  
  let [request_token, request_token_secret] = oauth#requestToken(request_token_url, config.consumer_key, config.consumer_secret)
  if has("win32") || has("win64")
    exe "!start rundll32 url.dll,FileProtocolHandler ".auth_url."?oauth_token=".request_token
  else
    call system("xdg-open '".auth_url."?oauth_token=".request_token."'")
  endif
  let verifier = input("PIN:")
  let [access_token, access_token_secret] = oauth#accessToken(access_token_url, config.consumer_key, config.consumer_secret, request_token, request_token_secret, {"oauth_verifier": verifier})
  let config.access_token = access_token
  let config.access_token_secret = access_token_secret
  call writefile([string(config)], configfile)
endif

let ret = oauth#get(notification_url, config.consumer_key, config.consumer_secret, config.access_token, config.access_token_secret, {})
let dom = xml#parse(ret.content)
for elem in dom.findAll("entry")
  echo elem.find("updated").value() . " " .  elem.find("title").value()
  echo "  " . elem.find("author").find("name").value()
  let summary = elem.find("summary")
  if !empty(summary)
    echo "  " . substitute(summary.value(), "\n", "\n  ", "g")
  endif
  echo "\n"
endfor
