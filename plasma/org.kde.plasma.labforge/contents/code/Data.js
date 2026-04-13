.pragma library

var MODEL_ORDER = [
    "claude-opus-4-6",
    "claude-sonnet-4-6",
    "claude-haiku-4-5",
    "gpt-5.3-codex",
    "gpt-5.4"
];

function normalizeBool(value) {
    if (value === null || value === undefined) {
        return null;
    }
    if (typeof value === "string") {
        var lowered = value.toLowerCase();
        if (lowered === "true" || lowered === "up" || lowered === "online" || lowered === "1") {
            return true;
        }
        if (lowered === "false" || lowered === "down" || lowered === "offline" || lowered === "0") {
            return false;
        }
        return null;
    }
    if (typeof value !== "boolean" && typeof value !== "number") {
        return null;
    }
    return !!value;
}

function _request(url, onSuccess, onError) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE) {
            return;
        }
        if ((xhr.status >= 200 && xhr.status < 300) || (xhr.status === 0 && xhr.responseText.length > 0)) {
            onSuccess(xhr.responseText);
            return;
        }
        onError("Request failed: " + url + " [" + xhr.status + "]");
    };
    xhr.open("GET", url);
    xhr.send();
}

function loadAll(onSuccess, onError) {
    var result = {
        modelStatus: null,
        budgetStatus: null,
        leaderboard: null,
        notices: []
    };
    var remaining = 4;
    var failed = false;

    function done() {
        remaining -= 1;
        if (!failed && remaining === 0) {
            onSuccess(result);
        }
    }

    function fail(message) {
        if (failed) {
            return;
        }
        failed = true;
        onError(message);
    }

    var nonce = Date.now();

    _request("https://www.labforge.top/model-status.json?t=" + nonce, function(text) {
        result.modelStatus = normalizeModelStatus(JSON.parse(text));
        done();
    }, fail);

    _request("https://www.labforge.top/budget-status.json?t=" + nonce, function(text) {
        result.budgetStatus = normalizeBudgetStatus(JSON.parse(text));
        done();
    }, fail);

    _request("https://www.labforge.top/leaderboard-data.js?t=" + nonce, function(text) {
        result.leaderboard = normalizeLeaderboard(text);
        done();
    }, fail);

    _request("https://www.labforge.top/?t=" + nonce, function(text) {
        result.notices = parseNotices(text);
        done();
    }, function() {
        result.notices = [];
        done();
    });
}

function normalizeModelStatus(payload) {
    var models = [];
    var rawModels = payload.models || {};
    for (var i = 0; i < MODEL_ORDER.length; i += 1) {
        var identifier = MODEL_ORDER[i];
        var raw = rawModels[identifier];
        if (!raw) {
            continue;
        }

        var history = raw.history || raw.recent_probes || raw.recentProbes || raw.probes || [];
        var last = history.length > 0 ? history[history.length - 1] : null;
        var okCount = 0;
        var probes = [];
        for (var j = 0; j < history.length; j += 1) {
            var probe = history[j];
            var ok = probe.ok;
            if (ok === undefined && probe.available !== undefined) {
                ok = probe.available;
            }
            if (ok === undefined && probe.success !== undefined) {
                ok = probe.success;
            }
            if (ok === undefined && probe.is_up !== undefined) {
                ok = probe.is_up;
            }
            if (ok === undefined && probe.isUp !== undefined) {
                ok = probe.isUp;
            }
            ok = normalizeBool(ok);
            if (ok === true) {
                okCount += 1;
            }
            probes.push({
                ok: ok,
                ms: probe.ms || probe.latency_ms || probe.latencyMs || 0,
                timestamp: probe.t || probe.timestamp || "--"
            });
        }
        var historyBars = probes.slice(Math.max(0, probes.length - 60));
        while (historyBars.length < 60) {
            historyBars.unshift(null);
        }
        var lastProbe = probes.length > 0 ? probes[probes.length - 1] : null;
        var fallbackAvailability = raw.available;
        if (fallbackAvailability === undefined) {
            fallbackAvailability = raw.is_up;
        }
        if (fallbackAvailability === undefined) {
            fallbackAvailability = raw.isUp;
        }

        models.push({
            identifier: identifier,
            name: raw.name || identifier,
            provider: raw.provider || "Unknown",
            latencyMs: lastProbe ? lastProbe.ms : (last ? (last.ms || 0) : 0),
            latestTimestamp: lastProbe ? lastProbe.timestamp : (last ? (last.t || "--") : "--"),
            isUp: lastProbe && lastProbe.ok !== null ? lastProbe.ok : normalizeBool(fallbackAvailability),
            successRate: history.length > 0 ? (okCount / history.length) : 0,
            successCount: okCount,
            totalCount: history.length,
            history: probes,
            historyBars: historyBars
        });
    }

    var upCount = 0;
    for (var k = 0; k < models.length; k += 1) {
        if (models[k].isUp) {
            upCount += 1;
        }
    }

    return {
        updatedAt: payload.updated_at || "--",
        pingMs: payload.ping_ms || 0,
        models: models,
        totalCount: models.length,
        upCount: upCount
    };
}

function normalizeBudgetStatus(payload) {
    return {
        updatedAt: payload.updated_at || "--",
        gpt: normalizeBudgetChannel(payload.gpt || {}, "GPT Budget"),
        claude: normalizeBudgetChannel(payload.claude || {}, "Claude Budget")
    };
}

function normalizeBudgetChannel(payload, fallbackTitle) {
    var spent = Number(payload.spent || 0);
    var budget = Number(payload.budget || 0);
    var ratio = budget > 0 ? Math.min(Math.max(spent / budget, 0), 1) : 0;
    return {
        title: payload.title || payload.label || fallbackTitle,
        description: payload.description || "",
        spent: spent,
        budget: budget,
        remaining: Math.max(0, budget - spent),
        usageRatio: ratio
    };
}

function normalizeLeaderboard(scriptText) {
    var match = scriptText.match(/window\.__LEADERBOARD__\s*=\s*(.+);/);
    var payload = match ? JSON.parse(match[1]) : { all: [], updated_at: "--" };
    return {
        updatedAt: payload.updated_at || "--",
        topEntries: (payload.all || []).slice(0, 3).map(function(item) {
            return {
                alias: item.alias || "Unknown",
                tokens: item.tokens || 0,
                claudeTokens: item.claude_tokens || 0,
                gptTokens: item.gpt_tokens || 0
            };
        })
    };
}

function parseNotices(html) {
    var match = html.match(/const\s+NOTICE_ITEMS\s*=\s*\[([\s\S]*?)\];/);
    if (!match) {
        return [];
    }
    var notices = [];
    var regex = /"((?:\\"|[^"])*)"/g;
    var innerMatch;
    while ((innerMatch = regex.exec(match[1])) !== null) {
        notices.push(innerMatch[1].replace(/\\"/g, "\""));
    }
    return notices;
}
