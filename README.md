## ContextMenu

### 1. Dynamic Context Engine
The resource automatically detects the entity type under the cursor (Vehicle, Ped, Player, Object, or World) and dynamically constructs the menu content in real-time.
-   **Smart Differentiation**: Distinguishes between NPCs, other Players, and the Local Player to provide relevant options.
-   **Network Awareness**: Automatically fetches NetIDs and Network Owners for networked entities.

### 2. Intelligent UI Positioning
The interface features a robust positioning system designed to keep the menu fully visible at all times:
-   **Smart Flip**: Automatically detects if the menu would go off-screen to the right and flips it to the left side of the parent item using CSS anchoring (`right: 100%`).
-   **Viewport Clamping**: Ensures the menu never clips off the screen edges by forcing a minimum distance from boundaries.
-   **Vertical Alignment**: Precise pixel-perfect alignment to match menu text with parent items.

### 3. Developer Tools Engine
Built-in utility for server development and debugging:
-   **One-Click Copy**: Any displayed data (Coordinates, Hash, IDs) can be copied to the clipboard instantly via NUI callbacks.
-   **Entity Metadata**: Retrieves deep entity information including Archetype names, Model Hashes, and Network Ownership.

### 4. Input & Dialog System
-   **NUI Overlay**: Custom HTML/CSS input dialogs (e.g., for vehicle spawning) that handle focus states and keyboard input without freezing the game engine unnecessarily.
-   **Focus Locking**: Unlocks the mouse cursor (ALT key) only when needed, maintaining immersion.

## 🎨 UI Components & Formatting

The resource exports a flexible API to build rich menus.

### Available Components
-   **Standard Item**: Basic clickable text item (`AddItem`).
-   **Submenu**: Opens a nested menu (`AddSubmenu`).
-   **Scrollable Submenu**: A submenu with a fixed height that scrolls (`AddScrollSubmenu`).
-   **Paged Submenu**: A submenu that organizes items into pages (`AddPageSubmenu`).
-   **Checkbox**: A toggleable item with an on/off state (`AddCheckboxItem`).
-   **Separator**: A fast visual divider line (`AddSeparator`).
-   **Right Text**: Add secondary text to the right side of any item using `RightText(itemId, "Text")`.

### Color Codes
You can use standard GTA-style color codes in any label or text:

| Code | Color       | Code | Color       |
| :--- | :---------- | :--- | :---------- |
| `~r~` | Red         | `~p~` | Purple      |
| `~b~` | Blue        | `~v~` | Magenta     |
| `~g~` | Green       | `~l~` | Black       |
| `~y~` | Yellow      | `~c~` | Grey        |
| `~o~` | Orange      | `~m~` | Dark Grey   |
| `~w~` | White (Reset)| `~s~` | White (Reset)|
| `~h~` | **Bold**    | `~n~` | New Line    |

*Note: The NUI automatically parses these codes into HTML spans.*

## 📦 Installation

1.  Place the `ContextMenu` folder in your `resources` directory.
2.  Add `ensure ContextMenu` to your `server.cfg`.

## 🎮 Usage

-   **Hold ALT**: Interaction Mode (Mouse Cursor).
-   **Right-Click**: Open Context Menu.
-   **Left-Click**: Interact with the entity under the cursor.
-   **Release ALT**: Close Menu.
-   **Demo**:  While interacting with the sky, right-click to access the **"Démo Features & Couleurs"** menu to test all UI components.

## 📜 License

Provided as-is for development and production use.
