document.querySelectorAll(".confetti").forEach(input => {
    input.addEventListener("keydown", (event) => {
        const { cursorX, cursorY } = getCursorPosition(input);
        createParticles(cursorX, cursorY, input);
    });
});

function createParticles(x, y, input) {
    const rect = input.getBoundingClientRect();
    const maxX = rect.right; 
    if (x > maxX) {
        x = maxX;
    }

    const burst = new mojs.Burst({
        left: x,
        top: y,
        radius: { 5: 25 },
        count: 6,
        children: {
            shape: "zigzag",
            radius: { 3: 6 },
            fill: ["#c97bb6", "#9e7144", "#dedda2"],
            duration: 500,
            easing: "cubic.out"
        }
    });
    burst.replay();
}

function getCursorPosition(input) {
    const rect = input.getBoundingClientRect();
    const textBeforeCursor = input.value.substring(0, input.selectionStart);
    const span = document.createElement('span');
    span.style.visibility = 'hidden';
    span.style.position = 'absolute';
    span.style.whiteSpace = 'pre';
    span.style.fontFamily = getComputedStyle(input).fontFamily;
    span.style.fontSize = getComputedStyle(input).fontSize;
    span.textContent = textBeforeCursor;
    document.body.appendChild(span);

    const cursorX = span.getBoundingClientRect().width + rect.left + 5;
    const cursorY = rect.top + rect.height / 2 + window.scrollY; 

    document.body.removeChild(span);

    return { cursorX, cursorY };
}
