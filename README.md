# lua-askpass

A cool askpass written in lua.

Install it from luarocks

```sh
luarocks install lua-askpass
```

or from Github

```sh
wget https://raw.githubusercontent.com/Absolpega/lua-askpass/main/askpass.lua
```
you need to launch sudo with the -A flag
so here's a snippet
```sh
export SUDO_ASKPASS="$(which askpass.lua 2> /dev/null)"
[ -n $SUDO_ASKPASS ] && alias sudo='sudo -A'
```
it sets an alias if you have askpass.lua in your PATH
