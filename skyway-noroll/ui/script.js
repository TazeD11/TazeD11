const root = document.getElementById('root');
const card = document.getElementById('card');
const titleEl = document.getElementById('title');
const messageEl = document.getElementById('message');
const counterEl = document.getElementById('counter');
const timerEl = document.getElementById('timer');
const fillEl = document.getElementById('fill');

const POSITIONS = [
    'top-right', 'top-left', 'top-center',
    'bottom-right', 'bottom-left', 'bottom-center', 'center'
];

let hideTimer = null;
let leaveTimer = null;
let rafId = null;

function clearTimers() {
    clearTimeout(hideTimer);
    clearTimeout(leaveTimer);
    cancelAnimationFrame(rafId);
}

function hide() {
    clearTimers();
    if (!card.classList.contains('show')) return;

    card.classList.remove('show');
    card.classList.add('hide');

    leaveTimer = setTimeout(() => {
        card.classList.remove('hide');
        card.style.opacity = 0;
    }, 360);
}

function startCountdown(freeze, seconds) {
    const start = performance.now();

    const tick = (now) => {
        const left = Math.max(0, freeze - (now - start));
        timerEl.textContent = (left / 1000).toFixed(1) + seconds;
        if (left > 0) rafId = requestAnimationFrame(tick);
    };

    rafId = requestAnimationFrame(tick);
}

function show(data) {
    clearTimers();

    POSITIONS.forEach((p) => root.classList.remove('pos-' + p));
    root.classList.add('pos-' + (POSITIONS.includes(data.position) ? data.position : 'top-right'));
    root.style.setProperty('--accent', data.accent || '#a855f7');
    root.style.setProperty('--freeze', data.freeze + 'ms');

    titleEl.textContent = data.title || '';
    messageEl.textContent = data.message || '';
    counterEl.textContent = data.counter || '';

    card.classList.remove('show', 'hide');
    fillEl.classList.remove('run');
    void card.offsetWidth;

    card.style.opacity = '';
    card.classList.add('show');
    fillEl.classList.add('run');

    startCountdown(data.freeze, data.seconds || 's');

    hideTimer = setTimeout(hide, data.duration);
}

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    if (data.action === 'notify') show(data);
    if (data.action === 'hide') hide();
});