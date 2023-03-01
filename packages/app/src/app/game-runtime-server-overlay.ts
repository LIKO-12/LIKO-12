import { loveEvents } from 'core/love-events';
import { ColouredText } from 'love.graphics';

const IDE_URL = 'https://liko-12.github.io/LIKO-IDE/';

const TITLE_TEXT = 'Waiting for LIKO-IDE to connect';
const SUBTITLE_TEXT = [
    [0xF5 / 255, 0xF5 / 255, 0xF5 / 255, 1],
    'Open ',
    [0xFA / 255, 0xA2 / 255, 0x1B / 255, 1],
    IDE_URL,
    [0xF5 / 255, 0xF5 / 255, 0xF5 / 255, 1],
    '\nin your browser to get started',
]satisfies ColouredText;

interface Point {
    x: number,
    y: number,
}

interface Rectangle extends Point {
    width: number,
    height: number,
}

function isInRectangle(x: number, y: number, rectangle: Rectangle) {
    return (
        rectangle.x <= x && x <= rectangle.x + rectangle.width &&
        rectangle.y <= y && y <= rectangle.y + rectangle.height
    );
}

/**
 * The logic for the UI displayed as an overlay over the LIKO-12 screen.
 * Responsible for displaying the status of the server.
 */
export class GameRuntimeServerOverlay {
    private readonly logoPosition: Point = { x: 0, y: 0 };
    private readonly titlePosition: Point = { x: 0, y: 0 };
    private readonly subTitlePosition: Point = { x: 0, y: 0 };

    private readonly linkArea: Rectangle = { x: 0, y: 0, width: 0, height: 0 };

    private readonly primaryFont = love.graphics.newFont('res/fonts/Roboto-Regular.ttf', 24);
    private readonly secondaryFont = love.graphics.newFont('res/fonts/Roboto-Regular.ttf', 16);

    private readonly normalCursor = love.mouse.getSystemCursor('arrow');
    private readonly linkCursor = love.mouse.getSystemCursor('hand');

    private readonly logoImage = love.graphics.newImage('res/icon.png');

    private linkHovered = false;

    constructor() {
        this.logoImage.setFilter('nearest', 'nearest');
        this.updateLayout();

        loveEvents.on('resize', () => this.updateLayout());
        loveEvents.on('draw', () => this.renderOverlay());
        loveEvents.on('mousemoved', () => this.updateCursor());
        loveEvents.on('mousepressed', (x: number, y: number, button: number) => this.onMousePressed(x, y, button));
    }

    private onMousePressed(x: number, y: number, button: number): void {
        if (button !== 1) return;
        if (isInRectangle(x, y, this.linkArea)) {
            love.system.openURL(IDE_URL);
        }
    }

    private updateCursor() {
        const [mouseX, mouseY] = love.mouse.getPosition();
        const hovered = isInRectangle(mouseX, mouseY, this.linkArea);

        if (hovered !== this.linkHovered) {
            love.mouse.setCursor(hovered ? this.linkCursor : this.normalCursor);
        }

        this.linkHovered = hovered;
    }

    private updateLayout() {
        const [windowWidth, windowHeight] = love.graphics.getDimensions();
        const anchorX = windowWidth * .5, anchorY = windowHeight * .5 + 70;

        this.logoPosition.x = anchorX;
        this.logoPosition.y = anchorY - 100;

        const primaryFontHeight = this.primaryFont.getHeight();
        const secondaryFontHeight = this.secondaryFont.getHeight();

        const titleWidth = this.primaryFont.getWidth(TITLE_TEXT);
        const openSegmentWidth = this.secondaryFont.getWidth('Open ');
        const linkSegmentWidth = this.secondaryFont.getWidth(IDE_URL);

        this.titlePosition.x = anchorX - titleWidth * .5;
        this.titlePosition.y = anchorY - primaryFontHeight;

        this.subTitlePosition.x = anchorX - (openSegmentWidth + linkSegmentWidth) * .5;
        this.subTitlePosition.y = anchorY + secondaryFontHeight * .25;

        this.linkArea.x = this.subTitlePosition.x + openSegmentWidth;
        this.linkArea.y = this.subTitlePosition.y;
        this.linkArea.width = linkSegmentWidth;
        this.linkArea.height = secondaryFontHeight;
    }

    private renderOverlay() {
        const [windowWidth, windowHeight] = love.graphics.getDimensions();

        love.graphics.setColor(0x0A / 255, 0x0A / 255, 0x0A / 255, 1);
        love.graphics.rectangle('fill', 0, 0, windowWidth, windowHeight);

        love.graphics.setColor(1, 1, 1, 1);
        love.graphics.draw(this.logoImage, this.logoPosition.x, this.logoPosition.y, 0, 7, 7, 8, 8);

        love.graphics.setColor(1, 1, 1, 1);

        love.graphics.setFont(this.primaryFont);
        love.graphics.printf(TITLE_TEXT, 0, this.titlePosition.y, windowWidth, 'center');

        love.graphics.setFont(this.secondaryFont);
        love.graphics.printf(SUBTITLE_TEXT, 0, this.subTitlePosition.y, windowWidth, 'center');

        love.graphics.setColor(0xFA / 255, 0xA2 / 255, 0x1B / 255, 1);
        love.graphics.rectangle('fill',
            this.linkArea.x, this.linkArea.y + this.linkArea.height - 3,
            this.linkArea.width - 1, 1);
    }
}