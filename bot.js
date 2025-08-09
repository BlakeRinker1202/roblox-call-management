const express = require("express");
const noblox = require("noblox.js");
const fetch = require("node-fetch");

const app = express();
app.use(express.json());

const PORT = 3000; // Same as in Roblox script
const GROUP_ID = 855648348;
const BOT_COOKIE = "YOUR_BOT_COOKIE_HERE"; // Bot account cookie
const WEBHOOK_URL = "https://webhook.lewisakura.moe/api/webhooks/1391891710333816954/qigb1E_ZVFsVTaNDs3hNpCladtKtmxvZVt11R-wkFCgmRWqZPOFm6UiQCsd9ZVsq5uh4";

// Rank tiers
const tier135_165 = [135, 145, 155, 165];
const tier175_205 = [175, 185, 195, 205];

function inArray(arr, val) {
    return arr.includes(val);
}

function canManage(userRank, targetRank) {
    if (userRank >= 135 && userRank <= 165) return false;
    if (userRank >= 175 && userRank <= 205) return inArray(tier135_165, targetRank);
    if (userRank >= 213) return inArray(tier175_205, targetRank) || inArray(tier135_165, targetRank);
    return false;
}

async function sendWebhookLog(actioner, action, target, oldRankName, newRankName) {
    const payload = {
        embeds: [{
            description: `**_${actioner}_** *${action}* **_${target}_**. Their current rank was **${oldRankName}**, and now their rank is **${newRankName}**`,
            color: parseInt("FFFFFF", 16)
        }]
    };
    await fetch(WEBHOOK_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
    });
}

app.post("/promote-demote", async (req, res) => {
    const { action, senderName, senderRank, targetName } = req.body;

    try {
        const targetId = await noblox.getIdFromUsername(targetName);
        const targetRank = await noblox.getRankInGroup(GROUP_ID, targetId);

        if (targetName.toLowerCase() === senderName.toLowerCase()) {
            return res.json({ success: false, message: "You cannot promote/demote yourself." });
        }

        if (targetRank >= senderRank) {
            return res.json({ success: false, message: "You cannot promote users above your rank." });
        }

        if (!canManage(senderRank, targetRank)) {
            return res.json({ success: false, message: "You cannot promote that user." });
        }

        const oldRankName = await noblox.getRankNameInGroup(GROUP_ID, targetId);

        if (action === "promote") {
            await noblox.promote(GROUP_ID, targetId);
        } else {
            await noblox.demote(GROUP_ID, targetId);
        }

        const newRankName = await noblox.getRankNameInGroup(GROUP_ID, targetId);

        await sendWebhookLog(senderName, action + "d", targetName, oldRankName, newRankName);

        res.json({ success: true, message: `${targetName} was successfully ${action}d. Their rank was ${oldRankName} and now their rank is ${newRankName}` });
    } catch (err) {
        console.error(err);
        res.json({ success: false, message: "Error processing request." });
    }
});

(async () => {
    await noblox.setCookie(BOT_COOKIE);
    console.log("Bot logged in.");
    app.listen(PORT, () => console.log(`Promotion bot listening on port ${PORT}`));
})();
