const CHARS = "abcdefghijklmnopqrstuvwxyzλλλ     ";

const getScrambled = (len) => {
    let scramble = '';
    for (let i = 0; i < len; i++) {
        const idx = Math.floor(Math.random() * CHARS.length);
        scramble += CHARS[idx];
    }
    return scramble;
};

// Parse a restricted subset of markdown formatting (currently only supports italics)
const parseMd = (md) => {
    let italics = false, segments = [], curSegment = '', size = 0;
    for (let i = 0; i < md.length; ++i) {
        if (md[i] == '*') {
            segments.push({italics: italics, segment: curSegment});
            curSegment = '';
            italics = !italics;
        } else {
            curSegment += md[i];
            ++size;
        }
    }
    segments.push({italics: italics, segment: curSegment});
    return {
        segments: segments,
        size: size,
    }
}

const printMd = (segments, prefix) => {
    let md = '';
    for (const {italics, segment} of segments) {
        if (prefix <= 0) break;
        if (italics) md += "<span class=\"italic\">";
        const sliceAmount = Math.min(prefix, segment.length);
        md += segment.substring(0, sliceAmount);
        prefix -= sliceAmount;
        if (italics) md += "</span>";
    }
    return md;
}

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

class Scramble {
    constructor(elem, target) {
        this.elem = elem;
        const parsedTarget = parseMd(target);
        this.targetSegments = parsedTarget.segments;
        this.targetSize = parsedTarget.size;
        this.upperBound = Math.round(0.7 * this.targetSize);
        this.intervalId = null;
        this.totalSize = 0;
        this.correctPrefix = 0;
    }

    step = () => {
        if (this.totalSize == this.upperBound) {
            if (this.correctPrefix == this.targetSize) {
                this.stop();
            } else {
                this.correctPrefix += 1;
                this.elem.innerHTML = (
                    printMd(this.targetSegments, this.correctPrefix)
                    + "<span class=\"text-zinc-700\">"
                    + getScrambled(this.upperBound - this.correctPrefix)
                    + "</span>"
                    + "<span class=\"opacity-0\">"
                    + "l".repeat(this.targetSize - Math.max(this.upperBound, this.correctPrefix))
                    + "</span>"
                );
            }
        } else {
            this.totalSize += 1;
            this.elem.innerHTML = (
                "<span class=\"text-zinc-700\">"
                + getScrambled(this.totalSize)
                + "</span>"
                + "<span class=\"opacity-0\">"
                + "l".repeat(this.targetSize - this.totalSize)
                + "</span>"
            );
        }
    }

    start = () => {
        this.intervalId = setInterval(this.step, 20);
    }

    stop = () => {
        clearInterval(this.intervalId);
    }
}

class Fade {
    constructor(elem, target) {
        this.elem = elem;
        const parsedTarget = parseMd(target);
        this.target = printMd(parsedTarget.segments, parsedTarget.size);
    }

    start = () => {
        this.elem.innerHTML = this.target;
        this.elem.style.opacity = 1;
    }
}
