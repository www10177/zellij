import { initConnectionHandlers } from './connection.js';
import { initAuthentication } from './auth.js';
import { initTerminal } from './terminal.js';
import { setupInputHandlers } from './input.js';
import { initWebSockets } from './websockets.js';

document.addEventListener("DOMContentLoaded", async (event) => {
    initConnectionHandlers();

    const webClientId = await initAuthentication();

    const { term, fitAddon } = initTerminal();
    const sessionName = location.pathname.split("/").pop();

    let sendAnsiKey = (ansiKey) => {
        // This will be replaced by the WebSocket module
    };
    
    setupInputHandlers(term, sendAnsiKey);

    document.title = sessionName;
    const websockets = initWebSockets(webClientId, sessionName, term, fitAddon, sendAnsiKey);
    
    // Update sendAnsiKey to use the actual WebSocket function returned by initWebSockets
    sendAnsiKey = websockets.sendAnsiKey;
    
    // Update the input handlers with the correct sendAnsiKey function
    setupInputHandlers(term, sendAnsiKey);
    initWebInputBar(sendAnsiKey, fitAddon);
});

function initWebInputBar(sendFunction, fitAddon) {
    const webInputBar = document.getElementById("web-input-bar");
    const webCommandInput = document.getElementById("web-command-input");
    const webCommandSendEnter = document.getElementById("web-command-send-enter");
    if (!webInputBar || !webCommandInput) return;

    const fitTerminal = () => {
        requestAnimationFrame(() => fitAddon.fit());
    };
    const updateReservedInputHeight = () => {
        const reservedHeight = Math.ceil(webInputBar.getBoundingClientRect().height + 18);
        document.documentElement.style.setProperty("--web-input-reserved-height", `${reservedHeight}px`);
        fitTerminal();
    };

    updateReservedInputHeight();
    new ResizeObserver(updateReservedInputHeight).observe(webInputBar);

    webInputBar.addEventListener("submit", (event) => {
        event.preventDefault();
        const text = webCommandInput.value;
        if (!text) return;

        sendFunction(text.replace(/\r?\n/g, "\r"));
        if (!webCommandSendEnter || webCommandSendEnter.checked) {
            sendFunction("\r");
        }
        webCommandInput.value = "";
        webCommandInput.focus();
        updateReservedInputHeight();
    });

    webCommandInput.addEventListener("keydown", (event) => {
        if (event.key !== "Enter" || event.shiftKey || event.isComposing) {
            return;
        }

        event.preventDefault();
        webInputBar.requestSubmit();
    });

    webCommandInput.addEventListener("input", updateReservedInputHeight);
}
