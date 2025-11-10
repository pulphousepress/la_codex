# la_admin

`la_admin` provides an in‑game administrative panel accessed via a keybind (default **F10**). The panel allows server operators to manage the Los Animales RP environment without using console commands. Actions include toggling enforcement modes for assets and weapons and controlling the population system.

## Features

* **Toggle Asset Registry Mode** – Switch between `off`, `warn` and `block` for `la_asset_registry` at runtime.
* **Toggle Weapon Limiter Mode** – Switch between `off`, `warn`, `block` and `strip` for `la_weapon_limiter`.
* **Resync or Clear NPCs** – Trigger `la_pop_resync` or `la_pop_clear` commands to refresh or remove static NPCs.
* **Protected Access** – Only users with the configured ACE permission (default `command`) may open the panel or perform actions.

## Usage

1. **Ensure** the resource after your core scripts:
   ```cfg
   ensure la_addons/la_radio
   ensure la_pop
   ensure la_asset_registry
   ensure la_weapon_limiter
   ensure la_admin
   ```
2. **Permissions:** Grant the desired Ace permission (default `command`) to your admin group. For example in `server.cfg`:
   ```cfg
   add_ace group.admin command allow
   ```
3. **Open Panel:** Press **F10** in game (or whatever key you set in `config.lua`). The panel will appear centered on the screen. Press **ESC** or F10 again to close it.
4. **Perform Actions:** Select a mode from the dropdowns and click **Apply**, or click the population buttons. A status message will display confirmation or errors.

## Configuration

Edit `config.lua` to adjust:

| Key | Description | Default |
|---|---|---|
| `Debug` | Print debug info. | `true` |
| `Key` | Key to toggle panel (string recognised by FiveM). | `"F10"` |
| `PermissionAce` | ACE permission required to open panel. | `"command"` |
| `Resources` | Table mapping friendly names to resource names. Must match your resources for asset registry, weapon limiter and population. | See file |

## Extending

* **Additional Actions:** Add buttons in `html/index.html` and handle them in `html/app.js`. On the server, extend the `la_admin:action` event handler to support new commands or exports.
* **UI Design:** Customise the panel appearance by editing `html/style.css`. Add icons, animations or re‑structure the layout.
* **Live Data:** Implement periodic fetches of current modes and display them in the UI so admins can see the current state at a glance.

`la_admin` simplifies server management and helps enforce the era‑specific rules of Los Animales RP through an easy to use interface.