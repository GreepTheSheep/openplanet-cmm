# Contributing guide for Community Matchmaking

For now, I don't recommend adding contributions for CMM because we are currently undergoing extensive testing. This will change well after the public release.

## How to contribute to the project?

If you're looking to contribute to the plugin, you will have to [fork the repository](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo) to make the changes you want to push to the project. Once you have the needed changes, you can commit them to your fork, then [open a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request) to get it reviewed and approved.

Pull requests that may use any sort of generative AI will be rejected.

## Requirements

* [Openplanet](https://openplanet.dev/)
* TM2020 Club access

As always, it's also **highly** recommended to read the [Openplanet documentation](https://openplanet.dev/docs/api), as well as its [tutorial / guide](https://openplanet.dev/docs/getting-started).

Lastly, for changes that require using methods / properties from the ManiaPlanet engine, it's recommended to read [the respective game's API documentation](https://next.openplanet.dev/)

## Running your own version on Openplanet

To test your changes locally, you will have to move the changed files to the Plugins folder in Openplanet. This is usually located at:

- `C:\Users\%username%\OpenplanetNext\Plugins\` for Trackmania Next / 2020

There, you can create a `CMM` folder with your files. Make sure `info.toml` is in the root folder (`CMM\info.toml`)!

Once you have done that, you will have to run the game in Developer mode. To do this, press F3 to bring up the Openplanet overlay, click Openplanet on the top left, Signature mode, Developer.

## Testing changes to CMM

If you want to contribute to CMM, you won't be able to join matchmaking like in normal CMM play. In Developer mode, you can't play most maps in a room (unless you are a trusted developer).

For now, I don't plan to create a matchmaking mode that grants access to the Openplanet's school maps.
That will be added well after CMM's public release.

You can read more about School mode and whitelisted maps [here](https://openplanet.dev/user/trusted).

## Debugging

To debug issues with the current code or your changes, debug logs are displayed when you're on Openplanet Developer signature. Logging messages can be found in the Openplanet log (F3 -> Openplanet -> Log).