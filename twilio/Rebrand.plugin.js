/**
 * @name Rebrand
 * @description Troca "Discord" por "Twilio" no título da janela.
 * @version 1.0.0
 */
module.exports = class Rebrand {
    start() {
        const fix = () => { if (document.title.includes("Discord")) document.title = document.title.replace(/Discord/g, "Twilio"); };
        this.obs = new MutationObserver(fix);
        this.obs.observe(document.head, {childList: true, subtree: true, characterData: true});
        fix();
    }
    stop() { this.obs?.disconnect(); }
};
