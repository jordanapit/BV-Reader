const { app, BrowserWindow, screen, ipcMain, dialog, nativeTheme, systemPreferences } = require('electron');
nativeTheme.themeSource = 'system';
app.commandLine.appendSwitch('disable-features', 'CalculateNativeWinOcclusion');
let mainWasMaximized = true;
const path = require('path');
const fs = require('fs');
let mainWindow = null;
let presentationWindow = null;

// ===== Membuka file PDF dari Explorer (file association) =====
let pendingPdfPath = null;

function findPdfInArgs(args, baseDir) {
  for (const arg of args) {
    if (typeof arg !== 'string' || !arg.toLowerCase().endsWith('.pdf')) continue;
    const fullPath = path.resolve(baseDir || process.cwd(), arg);
    if (fs.existsSync(fullPath)) return fullPath;
  }
  return null;
}

pendingPdfPath = findPdfInArgs(process.argv.slice(1));

// Hanya boleh ada satu jendela BV Reader. Kalau PDF lain di-double-click
// saat aplikasi sudah terbuka, PDF itu dibuka di jendela yang sudah ada.
const gotSingleLock = app.requestSingleInstanceLock();

app.on('second-instance', (event, argv, workingDirectory) => {
  if (!mainWindow || mainWindow.isDestroyed()) return;
  if (mainWindow.isMinimized()) mainWindow.restore();
  const pdfPath = findPdfInArgs(argv.slice(1), workingDirectory);
  if (pdfPath) {
    stopSlideshowRoutine();
    mainWindow.webContents.send('open-pdf', pdfPath);
  }
  mainWindow.focus();
});

ipcMain.handle('get-initial-pdf', () => {
  const pdfPath = pendingPdfPath;
  pendingPdfPath = null;
  return pdfPath;
});

function createMainWindow() {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 800,
    title: "BV Reader",
    icon: path.join(__dirname, 'app-icon.ico'),
    show: false,
    backgroundColor: '#00000000', // Transparan agar efek Mica Windows 11 terlihat
    backgroundMaterial: 'mica',   // Efek Mica native WinUI 3 (Windows 11)
    titleBarStyle: 'hidden',      // Sembunyikan titlebar bawaan yang kaku
    titleBarOverlay: {
      color: '#00000000',         // Menyatu dengan Mica background
      symbolColor: '#ffffff',     // Warna ikon Minimize, Maximize, Close
      height: 38                  // Tinggi area titlebar
    },
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  mainWindow.loadFile('index.html');
  mainWindow.setMenuBarVisibility(false);
  
  mainWindow.once('ready-to-show', () => {
    updateTitleBarColors();
    mainWindow.maximize();
    mainWindow.show();
  });

  mainWindow.on('closed', () => {
    if (presentationWindow && !presentationWindow.isDestroyed()) {
      presentationWindow.destroy();
    }
    app.quit();
  });
}

function createHiddenPresentationWindow() {
  presentationWindow = new BrowserWindow({
    width: 100,
    height: 100,
    x: -32000,
    y: -32000,
    show: false,
    opacity: 0,
    skipTaskbar: true,
    frame: false,
    fullscreenable: true,
    alwaysOnTop: true,
    backgroundColor: '#000000',
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
      backgroundThrottling: false
    }
  });

  presentationWindow.loadFile('presenter.html');
  
  presentationWindow.once('ready-to-show', () => {
    presentationWindow.showInactive();
  });

  presentationWindow.on('close', (e) => {
    if (mainWindow && !mainWindow.isDestroyed()) {
      e.preventDefault();
      stopSlideshowRoutine();
    }
  });
}

app.whenReady().then(() => {
  if (!gotSingleLock) {
    app.quit();
    return;
  }
  createMainWindow();
  createHiddenPresentationWindow();

  screen.on('display-added', sendDisplaysUpdate);
  screen.on('display-removed', sendDisplaysUpdate);
  screen.on('display-metrics-changed', sendDisplaysUpdate);

  systemPreferences.on('accent-color-changed', (event, newColor) => {
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send('accent-color-changed', '#' + newColor.slice(0, 6));
    }
  });
});

function sendDisplaysUpdate() {
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.webContents.send('displays-updated', getFormattedDisplays());
  }
}

function getFormattedDisplays() {
  const displays = screen.getAllDisplays();
  const primary = screen.getPrimaryDisplay();
  return displays.map((d, index) => ({
    id: d.id,
    label: `${d.label || 'Display ' + (index + 1)} (${d.bounds.width}x${d.bounds.height})${d.id === primary.id ? ' [Primary]' : ''}`,
    bounds: d.bounds
  }));
}

ipcMain.handle('get-displays', () => {
  return getFormattedDisplays();
});

ipcMain.handle('open-file-dialog', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    title: 'Open PDF File - BV Reader',
    filters: [{ name: 'PDF Files', extensions: ['pdf'] }],
    properties: ['openFile']
  });
  if (!result.canceled && result.filePaths.length > 0) {
    return result.filePaths[0];
  }
  return null;
});

ipcMain.on('preload-pdf', (event, { pdfSource, transition }) => {
  if (!presentationWindow || presentationWindow.isDestroyed()) {
    createHiddenPresentationWindow();
  }
  presentationWindow.webContents.send('preload-document', { pdfSource, transition });
});

ipcMain.on('set-transition', (event, transition) => {
  if (presentationWindow && !presentationWindow.isDestroyed()) {
    presentationWindow.webContents.send('update-transition', transition);
  }
});

ipcMain.on('start-slideshow', (event, { startPage, presenterDisplayId, audienceDisplayId, transition }) => {
  const displays = screen.getAllDisplays();

  if (displays.length === 1 || presenterDisplayId === audienceDisplayId) {
    mainWasMaximized = mainWindow.isMaximized();
    mainWindow.setFullScreen(true);
    mainWindow.webContents.send('mode-changed', { mode: 'single-fullscreen', page: startPage });
  } else {
    const presenterDisplay = displays.find(d => d.id === Number(presenterDisplayId)) || displays[0];
    const audienceDisplay = displays.find(d => d.id === Number(audienceDisplayId)) || displays[1];

    const currentDisplay = screen.getDisplayMatching(mainWindow.getBounds());
    if (currentDisplay.id !== presenterDisplay.id) {
      mainWindow.unmaximize();
      mainWindow.setBounds(presenterDisplay.bounds);
      mainWindow.maximize();
    }
    mainWindow.webContents.send('mode-changed', { mode: 'presenter', page: startPage });

    if (!presentationWindow || presentationWindow.isDestroyed()) {
      createHiddenPresentationWindow();
    }

    presentationWindow.setBounds(audienceDisplay.bounds);
    presentationWindow.setFullScreen(true);
    presentationWindow.webContents.send('show-presentation', { page: startPage, transition });
    presentationWindow.setOpacity(1);
    
    setTimeout(() => {
      if (mainWindow && !mainWindow.isDestroyed()) mainWindow.focus();
    }, 100);
  }
});

ipcMain.on('sync-page', (event, { pageNum, transition }) => {
  if (presentationWindow && !presentationWindow.isDestroyed()) {
    presentationWindow.webContents.send('render-page', { pageNum, transition });
  }
});

function stopSlideshowRoutine() {
  if (presentationWindow && !presentationWindow.isDestroyed()) {
    presentationWindow.webContents.send('hide-presentation');
    presentationWindow.setOpacity(0);
    presentationWindow.setFullScreen(false);
    presentationWindow.setBounds({ x: -32000, y: -32000, width: 100, height: 100 });
  }
  if (mainWindow && !mainWindow.isDestroyed()) {
    if (mainWindow.isFullScreen()) {
      mainWindow.setFullScreen(false);
      if (mainWasMaximized) mainWindow.maximize();
    }
    mainWindow.webContents.send('mode-changed', { mode: 'normal' });
    mainWindow.focus();
  }
}

ipcMain.on('stop-slideshow', () => {
  stopSlideshowRoutine();
});


// ===== Tema: Light / Dark / Ikuti Windows =====
function updateTitleBarColors() {
  if (!mainWindow || mainWindow.isDestroyed()) return;
  mainWindow.setTitleBarOverlay({
    color: '#00000000',
    symbolColor: nativeTheme.shouldUseDarkColors ? '#ffffff' : '#000000',
    height: 38
  });
}

nativeTheme.on('updated', updateTitleBarColors);

ipcMain.on('set-theme', (event, theme) => {
  if (['system', 'light', 'dark'].includes(theme)) {
    nativeTheme.themeSource = theme;
  }
});

// ===== Warna aksen (Accent Color) Windows =====
ipcMain.handle('get-accent-color', () => {
  return '#' + systemPreferences.getAccentColor().slice(0, 6);
});