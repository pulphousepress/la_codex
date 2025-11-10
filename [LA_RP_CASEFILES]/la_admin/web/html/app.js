// la_admin NUI app.js
window.addEventListener('DOMContentLoaded', () => {
    const panel = document.getElementById('panel');
    const assetModeSelect = document.getElementById('assetMode');
    const assetApplyBtn = document.getElementById('assetApply');
    const weaponModeSelect = document.getElementById('weaponMode');
    const weaponApplyBtn = document.getElementById('weaponApply');
    const popResyncBtn = document.getElementById('popResync');
    const popClearBtn = document.getElementById('popClear');
    const status = document.getElementById('status');

    function showPanel() {
        panel.style.display = 'block';
    }
    function hidePanel() {
        panel.style.display = 'none';
    }
    function setStatus(msg) {
        status.innerText = msg;
    }
    function sendAction(action, mode) {
        fetch('https://'+GetParentResourceName()+'/adminAction', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ action: action, mode: mode })
        });
        // The server will respond via la_admin:response event; no need to handle here
    }
    assetApplyBtn.addEventListener('click', () => {
        const mode = assetModeSelect.value;
        sendAction('setAssetMode', mode);
    });
    weaponApplyBtn.addEventListener('click', () => {
        const mode = weaponModeSelect.value;
        sendAction('setWeaponMode', mode);
    });
    popResyncBtn.addEventListener('click', () => {
        sendAction('popResync');
    });
    popClearBtn.addEventListener('click', () => {
        sendAction('popClear');
    });
    window.addEventListener('message', (event) => {
        const data = event.data;
        if (data.action === 'show') {
            showPanel();
        } else if (data.action === 'hide') {
            hidePanel();
        } else if (data.action === 'status') {
            // Display status returned from server
            if (data.status && data.status.status) {
                if (data.status.status === 'ok') {
                    setStatus('Action successful');
                } else {
                    setStatus('Error: '+(data.status.message || 'Unknown'));
                }
            }
        }
    });
});