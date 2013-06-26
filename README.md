# Dashboard

## Installation

### dependencies

```bash
gem install bundler
bundle install
dashing start -a 127.0.0.1 -p 3030 -u www-data -g www-data -d
```

### Env variables

```
# Thruk
export THRUK_URI='http://monitoring.domain.tld'
export THRUK_USER='dashboard'
export THRUK_PASSWORD=''

# Papertrail API
export PAPERTRAIL_TOKEN=''
```

## Bonus : Raspberry Pi config

### Start browser on boot

Install chromium, x11 server utils and unclutter :

```
apt-get install chromium x11-xserver-utils unclutter xscreensaver
```

edit `/etc/xdg/lxsession/LXDE/autostart` :

```
@lxpanel --profile LXDE
@pcmanfm --desktop --profile LXDE
# @xscreensaver -no-splash
@xset s off       # Turn off screensaver
@xset -dpms       # Turn off power saving
@xset s noblank   # Disable screen blanking
@unclutter        # Hide the mouse cursor
@midori -e Fullscreen -a  http://dashboard.domain.tld       # Launch dashboard at boot in midori
#@chromium --kiosk --incognito http://dashboard.domain.tld  # Or in Chromium
```

### Screen resolution

```
# get screen resolution
/opt/vc/bin/tvservice -s

# add to /boot/config.txt :
overscan_left=-40
overscan_right=-40
overscan_top=-40
overscan_bottom=-40
```

## Disable Power saving

edit `/etc/kbd/config`

```
BLANK_TIME=0
POWERDOWN_TIME=0
```

## Ressources

* [Dashing documentation](http://shopify.github.com/dashing)
* [Cooking up an Office Dashboard Pi](https://gocardless.com/blog/raspberry-pi-metric-dashboards/)
