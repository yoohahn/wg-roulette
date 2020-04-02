# wg-roulette 🎲

Need to run this as root or better put it in the roots cronjob to run every 10 minutes or so
It simply picks a random wireguard config from the `conf` folder and establish a new tunnel `wg0` using the random config file

```
*/10 * * * * /root/git/wg-roulette/run.sh
```
