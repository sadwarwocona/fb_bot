# s.sh

A small Telegram support bot in one Bash script. A person writes to the bot in a private chat. The bot forwards that message to an admin group. When someone in the group replies to the forwarded message, the bot copies the reply back to the person. This still works if that person hides their account on forwarded messages.

## Requirements

- bash
- curl
- jq

## Setup

Open `s.sh` and set three values at the top:

- `bot` — the bot username, without `@`. The script also uses this as the working directory name.
- `tkn` — the bot token from BotFather.
- `grp` — the admin supergroup id. It looks like `-100...`.

Create a group for the people who will answer. Add the bot and make it an admin, so it can see their replies. Turn on chat history for new members. That converts the group into a supergroup right away. If you do this later, the id changes and `grp` stops matching.

In Telegram Desktop open Settings, then Advanced, then Experimental settings, and turn on Show Peer IDs in Profile. Open the supergroup profile. The id shown there has no `-100` in front. Add `-100` and put the result in `grp`. A profile id `1356415630` becomes `-1001356415630`.

Do not publish a copy of the script that still contains a real token.

On startup the script creates `$bot` in the current directory and works from there. It also creates three files in that directory if they are absent:

- `ban` — chat ids to ignore, one id per line. An empty file means nobody is ignored. There is no ban command. Edit this file by hand. A new line is picked up on the next message, without a restart. The same Desktop setting shows a person's id in their profile. That number goes in `ban` as it is, with no `-100` prefix.
- `for_reply` — links a person's message to the forwarded copy in the group, so a reply can be threaded back.
- `datasheet` — remembers a private chat id when Telegram hides the sender of a forward.

Leave `for_reply` and `datasheet` in place while the bot is in use. Deleting them breaks replies to messages that were already forwarded.

The `/start` greeting is the `text=` string near the end of `s.sh`. Change it there.

To run several bots on one server, copy `s.sh` once per bot and rename each copy to that bot's username. Set `bot`, `tkn` and `grp` carefully in every copy. Each script runs `mkdir -p $bot` and then works in that directory, so the bots do not share `ban`, `for_reply` or `datasheet`. Start each copy from the directory where its folder should appear.

## Run

Run it inside `screen`. If you start `bash s.sh` in an SSH session and then close the terminal, the bot dies with that session.

```bash
screen -S bot
bash s.sh
```

Detach with Ctrl-A then D. The bot keeps polling. Attach again with `screen -r bot`. Stop the bot with Ctrl-C while attached. `tmux` works the same way.

After a reboot the `screen` or `tmux` session is gone, so start the bot again.

## Git

`.gitignore` tells Git which names not to add. It does not hide a file that is already committed.

The script creates a folder named `$bot` in the directory where you start it. Start it outside the clone, for example from `~/bots`, and that folder never enters the repository. If you start it inside the clone, `.gitignore` still skips every subdirectory and the files `ban`, `for_reply` and `datasheet`.

Do not commit `s.sh` while `tkn` holds a real token.

## License

MIT License. You can use, change, and ship this for any purpose, including commercial work. See `LICENSE`.
