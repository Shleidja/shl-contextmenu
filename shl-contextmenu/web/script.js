// ============================================================================
// DOM References
// ============================================================================

const rootMenu = document.getElementById('context-menu');
const dialogOverlay = document.getElementById('spawnVehicleDialogOverlay');
const vehicleInput = document.getElementById('vehicleNameInputNUI');

// ============================================================================
// NUI Message Handler
// ============================================================================

window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'openMenu':
            buildMenu(rootMenu, data.items, 'default', 10);
            showMenu(data.x, data.y);
            break;

        case 'closeMenu':
            hideAll();
            break;

        case 'copyToClipboard':
            handleClipboard(data.text);
            break;

        case 'showSpawnVehicleDialog':
            hideAll(true);
            dialogOverlay.style.display = 'flex';
            vehicleInput.focus();
            break;
    }
});

// ============================================================================
// Keyboard Handler
// ============================================================================

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        if (dialogOverlay.style.display === 'flex') {
            dialogOverlay.style.display = 'none';
            fetch(`https://${GetParentResourceName()}/cancelSpawnVehicleDialog`, { method: 'POST' });
        } else {
            hideAll();
        }
    }
});

// ============================================================================
// GTA Color Code Parser
// ============================================================================

const colorMap = {
    '~r~': 'text-red',
    '~b~': 'text-blue',
    '~g~': 'text-green',
    '~y~': 'text-yellow',
    '~o~': 'text-orange',
    '~c~': 'text-grey',
    '~m~': 'text-darkgrey',
    '~p~': 'text-purple',
    '~v~': 'text-magenta',
    '~q~': 'text-magenta',
    '~l~': 'text-black',
    '~u~': 'text-black',
    '~w~': '',
    '~s~': '',
};

/**
 * Parse les codes couleur GTA (~r~, ~b~, etc.) en HTML avec spans.
 */
function parseText(text) {
    if (!text) return '';

    const regex = /(~[a-z0-9_* ]+~)/gi;
    let segments = text.split(regex);
    let output = '';
    let openSpans = 0;
    let isBold = false;
    let isItalic = false;

    const closeAll = () => {
        let footer = '';
        while (openSpans > 0) {
            footer += '</span>';
            openSpans--;
        }
        if (isBold) { footer += '</span>'; isBold = false; }
        if (isItalic) { footer += '</span>'; isItalic = false; }
        return footer;
    };

    segments.forEach(seg => {
        const lowerSeg = seg.toLowerCase();

        if (regex.test(seg)) {
            if (colorMap.hasOwnProperty(lowerSeg)) {
                if (openSpans > 0) {
                    output += '</span>';
                    openSpans--;
                }
                const cls = colorMap[lowerSeg];
                if (cls) {
                    output += `<span class="${cls}">`;
                    openSpans++;
                }
            } else if (lowerSeg === '~h~' || lowerSeg === '~b~' && !colorMap[lowerSeg]) {
                if (!isBold) {
                    output += '<span class="bold">';
                    isBold = true;
                }
            } else if (lowerSeg === '~i~') {
                if (!isItalic) {
                    output += '<span class="italic">';
                    isItalic = true;
                }
            } else if (lowerSeg === '~n~') {
                output += '<br>';
            } else if (lowerSeg === '~s~') {
                output += closeAll();
            }
        } else {
            output += seg;
        }
    });

    output += closeAll();
    return output;
}

// ============================================================================
// Menu Construction
// ============================================================================

/**
 * Construit le contenu d'un menu dans un container DOM.
 */
function buildMenu(container, items, type = 'default', maxItems = 10) {
    container.innerHTML = '';

    if (type === 'scroll') {
        container.classList.add('scrollable');
        const maxHeight = (maxItems * 3.4) + 1;
        container.style.maxHeight = `${maxHeight}rem`;
    } else {
        container.classList.remove('scrollable');
        container.style.maxHeight = '';
    }

    if (type === 'page') {
        renderPage(container, items, maxItems, 0);
    } else {
        renderItems(container, items);
    }
}

/**
 * Rend une liste d'items dans un container.
 */
function renderItems(container, items) {
    items.forEach(item => {
        const el = createMenuItemElement(item);
        if (item.type === 'submenu' && item.items) {
            const subContainer = document.createElement('div');
            subContainer.className = 'context-menu';
            buildMenu(subContainer, item.items, item.menuType || 'default', item.maxItems || 10);
            el.appendChild(subContainer);
        }
        container.appendChild(el);
    });
}

// ============================================================================
// Pagination
// ============================================================================

/**
 * Rend une page spécifique d'un menu paginé.
 */
function renderPage(container, items, maxItems, currentPage) {
    container.innerHTML = '';

    const totalPages = Math.ceil(items.length / maxItems);
    const startIdx = currentPage * maxItems;
    const endIdx = startIdx + maxItems;
    const currentItems = items.slice(startIdx, endIdx);

    renderItems(container, currentItems);

    if (totalPages > 1) {
        const controls = document.createElement('div');
        controls.className = 'pagination-controls';

        const prevBtn = document.createElement('button');
        prevBtn.className = 'pagination-btn';
        prevBtn.innerText = '<';
        prevBtn.onclick = (e) => {
            e.stopPropagation();
            if (currentPage > 0) renderPage(container, items, maxItems, currentPage - 1);
        };

        const info = document.createElement('span');
        info.className = 'pagination-info';
        info.innerText = `${currentPage + 1}/${totalPages}`;

        const nextBtn = document.createElement('button');
        nextBtn.className = 'pagination-btn';
        nextBtn.innerText = '>';
        nextBtn.onclick = (e) => {
            e.stopPropagation();
            if (currentPage < totalPages - 1) renderPage(container, items, maxItems, currentPage + 1);
        };

        controls.appendChild(prevBtn);
        controls.appendChild(info);
        controls.appendChild(nextBtn);
        container.appendChild(controls);
    }
}

// ============================================================================
// Menu Item Element
// ============================================================================

/**
 * Crée un élément DOM pour un item de menu.
 */
function createMenuItemElement(item) {
    if (item.type === 'separator') {
        const sep = document.createElement('div');
        sep.className = 'menu-separator';
        return sep;
    }

    const el = document.createElement('div');
    el.className = 'menu-item';

    let labelHtml = parseText(item.label);
    let content = '';

    if (item.type === 'checkbox') {
        content += `<div class="checkbox-indicator ${item.checked ? 'checked' : ''}"></div>`;
    }
    content += `<span class="label">${labelHtml}</span>`;

    if (item.rightText) {
        content += `<span class="right-text">${parseText(item.rightText)}</span>`;
    }

    if (item.type === 'submenu') {
        content += `<div class="arrow"></div>`;
    }

    el.innerHTML = content;

    // Hover: ferme les sous-menus frères, ouvre le sien
    el.onmouseenter = () => {
        const parent = el.parentElement;
        if (parent) {
            Array.from(parent.children).forEach(child => {
                if (child.classList.contains('menu-item')) {
                    child.classList.remove('hovered');
                    const siblingSub = child.querySelector('.context-menu');
                    if (siblingSub) siblingSub.classList.remove('visible');
                }
            });
        }

        el.classList.add('hovered');

        const submenu = el.querySelector('.context-menu');
        if (submenu) {
            submenu.classList.add('visible');
            positionSubmenu(el, submenu);
        }
    };

    // Click: déclenche l'action ou toggle la checkbox
    el.onclick = (e) => {
        e.stopPropagation();
        if (item.type === 'submenu') return;

        fetch(`https://${GetParentResourceName()}/triggerAction`, {
            method: 'POST',
            body: JSON.stringify({ id: item.id })
        });

        if (item.type === 'checkbox') {
            const indicator = el.querySelector('.checkbox-indicator');
            if (indicator) {
                indicator.classList.toggle('checked');
            }
            item.checked = !item.checked;
        }

        if (!item.keepOpen && item.type !== 'checkbox') {
            // Le menu se ferme au relâchement de ALT (géré côté Lua)
        }
    };

    return el;
}

// ============================================================================
// Submenu Positioning
// ============================================================================

/**
 * Positionne un sous-menu par rapport à son item parent,
 * avec gestion des collisions écran (flip horizontal + clamp vertical).
 */
function positionSubmenu(parentItem, submenu) {
    const itemRect = parentItem.getBoundingClientRect();
    const subRect = submenu.getBoundingClientRect();
    const screenW = window.innerWidth;
    const screenH = window.innerHeight;

    const spaceRight = screenW - itemRect.right;

    submenu.style.left = '';
    submenu.style.right = '';
    submenu.style.marginLeft = '';
    submenu.style.marginRight = '';

    // Flip horizontal si pas assez de place à droite
    if (spaceRight < subRect.width) {
        submenu.style.right = '100%';
        submenu.style.marginRight = '0.6rem';
    } else {
        submenu.style.left = '100%';
        submenu.style.marginLeft = '0.6rem';
    }

    // Alignement vertical
    let top = -4;
    const subHeight = subRect.height || 200;
    const spaceBottom = screenH - itemRect.top;

    if (spaceBottom < subHeight) {
        top = -(subHeight - itemRect.height);
        const absoluteTop = itemRect.top + top;
        if (absoluteTop < 0) {
            top = -itemRect.top + 5;
        }
    }

    submenu.style.top = `${top}px`;

    // Clamp aux bords de l'écran après le layout
    requestAnimationFrame(() => {
        submenu.style.opacity = '1';
        submenu.style.visibility = 'visible';

        const rect = submenu.getBoundingClientRect();

        if (rect.right > screenW) {
            const parentRect = parentItem.getBoundingClientRect();
            const targetCssLeft = (screenW - rect.width - 5) - parentRect.left;
            submenu.style.left = `${targetCssLeft}px`;
            submenu.style.right = 'auto';
        }

        if (rect.left < 0) {
            const parentRect = parentItem.getBoundingClientRect();
            const targetCssLeft = 5 - parentRect.left;
            submenu.style.left = `${targetCssLeft}px`;
            submenu.style.right = 'auto';
        }
    });
}

// ============================================================================
// Scroll Handler (bypass GTA input interception)
// ============================================================================



// ============================================================================
// Right-Click Listener
// ============================================================================

window.addEventListener('mousedown', (e) => {
    if (e.button === 2) {
        const x = e.clientX / window.innerWidth;
        const y = e.clientY / window.innerHeight;

        fetch(`https://${GetParentResourceName()}/requestOpenCoordinates`, {
            method: 'POST',
            body: JSON.stringify({ x: x, y: y })
        });
    }
});

// ============================================================================
// Menu Visibility
// ============================================================================

/**
 * Affiche le menu root à la position donnée (normalisée ou pixels).
 */
function showMenu(x, y) {
    rootMenu.classList.add('visible');

    let posX = x;
    let posY = y;
    if (x <= 1.0 && y <= 1.0) {
        posX = x * window.innerWidth;
        posY = y * window.innerHeight;
    }

    const rect = rootMenu.getBoundingClientRect();
    if (posX + rect.width > window.innerWidth) posX = window.innerWidth - rect.width - 5;
    if (posY + rect.height > window.innerHeight) posY = window.innerHeight - rect.height - 5;

    rootMenu.style.left = `${posX}px`;
    rootMenu.style.top = `${posY}px`;
}

/**
 * Cache tous les menus visibles.
 */
function hideAll(skipCallback = false) {
    rootMenu.classList.remove('visible');

    Array.from(document.querySelectorAll('.context-menu.visible')).forEach(el => {
        if (el !== rootMenu) el.classList.remove('visible');
    });

    if (!skipCallback) {
        fetch(`https://${GetParentResourceName()}/closeMenu`, { method: 'POST', body: '{}' }).catch(() => { });
    }
}

// ============================================================================
// Clipboard
// ============================================================================

function handleClipboard(text) {
    const el = document.createElement('textarea');
    el.value = text;
    document.body.appendChild(el);
    el.select();
    document.execCommand('copy');
    document.body.removeChild(el);
}

// ============================================================================
// Vehicle Spawn Dialog
// ============================================================================

vehicleInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
        const val = vehicleInput.value.trim();
        if (val) {
            fetch(`https://${GetParentResourceName()}/submitVehicleNameToSpawn`, {
                method: 'POST',
                body: JSON.stringify({ vehicleName: val })
            });
            vehicleInput.value = '';
            dialogOverlay.style.display = 'none';
        }
    } else if (e.key === 'Escape') {
        dialogOverlay.style.display = 'none';
        fetch(`https://${GetParentResourceName()}/cancelSpawnVehicleDialog`, { method: 'POST' });
    }
});