// ============ DOM 元素 ============
const heartsContainer = document.getElementById('heartsContainer');
const photoArea = document.getElementById('photoArea');
const photoInput = document.getElementById('photoInput');
const photoPlaceholder = document.getElementById('photoPlaceholder');
const photoPreview = document.getElementById('photoPreview');
const photoChangeBtn = document.getElementById('photoChangeBtn');
const nameInput = document.getElementById('nameInput');
const messageInput = document.getElementById('messageInput');
const charCount = document.getElementById('charCount');
const loveBtn = document.getElementById('loveBtn');
const hiddenMessage = document.getElementById('hiddenMessage');
const responseName = document.getElementById('responseName');
const responseMessage = document.getElementById('responseMessage');
const resetBtn = document.getElementById('resetBtn');

// ============ 初始化 ============
function init() {
  updateCharCount();
  startFallingHearts();
  bindEvents();
}

// ============ 爱心飘落 ============
function startFallingHearts() {
  const heartEmojis = ['💖', '💕', '💗', '💝', '💘', '💓', '❤️', '🩷', '💞', '🫶'];
  
  function createHeart() {
    const heart = document.createElement('span');
    heart.className = 'falling-heart';
    heart.textContent = heartEmojis[Math.floor(Math.random() * heartEmojis.length)];
    heart.style.left = Math.random() * 100 + '%';
    heart.style.fontSize = (Math.random() * 20 + 16) + 'px';
    heart.style.animationDuration = (Math.random() * 6 + 6) + 's';
    heart.style.animationDelay = Math.random() * 2 + 's';
    heartsContainer.appendChild(heart);

    // 动画结束后移除
    const duration = parseFloat(heart.style.animationDuration) + parseFloat(heart.style.animationDelay);
    setTimeout(() => {
      heart.remove();
    }, duration * 1000 + 500);
  }

  // 初始生成几个
  for (let i = 0; i < 5; i++) {
    setTimeout(createHeart, i * 600);
  }

  // 持续生成
  setInterval(createHeart, 1500);
}

// ============ 事件绑定 ============
function bindEvents() {
  // 图片上传
  photoArea.addEventListener('click', (e) => {
    if (e.target !== photoChangeBtn) {
      photoInput.click();
    }
  });
  photoInput.addEventListener('change', handlePhotoUpload);
  photoChangeBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    photoInput.click();
  });

  // 姓名输入
  nameInput.addEventListener('input', updateResponseName);

  // 寄语输入
  messageInput.addEventListener('input', () => {
    updateCharCount();
    updateResponseMessage();
  });

  // 表白按钮
  loveBtn.addEventListener('click', handleLoveClick);

  // 重置按钮
  resetBtn.addEventListener('click', handleReset);

  // 键盘支持：回车表白
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !hiddenMessage.classList.contains('visible')) {
      e.preventDefault();
      loveBtn.click();
    }
  });
}

// ============ 图片上传 ============
function handlePhotoUpload(e) {
  const file = e.target.files[0];
  if (!file) return;

  // 验证文件类型
  const validTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
  if (!validTypes.includes(file.type)) {
    alert('请上传 JPG / PNG / WebP / GIF 格式的图片');
    return;
  }

  // 验证文件大小（限制 10MB）
  if (file.size > 10 * 1024 * 1024) {
    alert('图片大小不能超过 10MB');
    return;
  }

  const reader = new FileReader();
  reader.onload = function(e) {
    photoPreview.src = e.target.result;
    photoArea.classList.add('has-image');
    
    // 图片加载动画
    photoPreview.style.animation = 'fadeInUp 0.5s ease';
    setTimeout(() => {
      photoPreview.style.animation = '';
    }, 500);
  };
  reader.readAsDataURL(file);
}

// ============ 字符计数 ============
function updateCharCount() {
  const len = messageInput.value.length;
  charCount.textContent = `${len}/200`;
  if (len >= 190) {
    charCount.style.color = '#ff4757';
  } else if (len >= 160) {
    charCount.style.color = '#ffa502';
  } else {
    charCount.style.color = '#c9a0b0';
  }
}

// ============ 更新响应内容 ============
function updateResponseName() {
  const name = nameInput.value.trim();
  responseName.textContent = name ? `亲爱的 ${name}` : '亲爱的';
}

function updateResponseMessage() {
  const msg = messageInput.value.trim();
  responseMessage.textContent = msg || '我也好喜欢你！';
}

// ============ 表白按钮点击 ============
function handleLoveClick() {
  const name = nameInput.value.trim();

  // 如果没填名字，给个温柔提示
  if (!name) {
    shakeElement(nameInput);
    nameInput.focus();
    nameInput.placeholder = '请先输入 Ta 的名字哦~ 💕';
    setTimeout(() => {
      nameInput.placeholder = '输入 Ta 的名字...';
    }, 2000);
    return;
  }

  // 更新隐藏信息中的名字
  updateResponseName();
  updateResponseMessage();

  // 按钮特效
  loveBtn.classList.add('clicked');
  setTimeout(() => loveBtn.classList.remove('clicked'), 600);

  // 按钮粒子特效
  createSparkles();

  // 烟花特效
  createConfetti();

  // 延迟显示隐藏信息
  setTimeout(() => {
    hiddenMessage.classList.add('visible');
    hiddenMessage.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }, 800);

  // 隐藏按钮
  loveBtn.style.display = 'none';
}

// ============ 按钮粒子 ============
function createSparkles() {
  const btnRect = loveBtn.getBoundingClientRect();
  const sparkleContainer = loveBtn.querySelector('.btn-sparkle');
  
  for (let i = 0; i < 16; i++) {
    const particle = document.createElement('span');
    particle.className = 'sparkle-particle';
    const angle = (Math.PI * 2 * i) / 16;
    const distance = 40 + Math.random() * 40;
    particle.style.setProperty('--tx', Math.cos(angle) * distance + 'px');
    particle.style.setProperty('--ty', Math.sin(angle) * distance + 'px');
    particle.style.left = '50%';
    particle.style.top = '50%';
    particle.style.width = (4 + Math.random() * 8) + 'px';
    particle.style.height = particle.style.width;
    particle.style.background = ['#ff69b4', '#ff1493', '#ffb6c1', '#ff4757', '#ff6b81'][Math.floor(Math.random() * 5)];
    sparkleContainer.appendChild(particle);
    
    setTimeout(() => particle.remove(), 800);
  }
}

// ============ 烟花彩纸特效 ============
function createConfetti() {
  const colors = [
    '#ff69b4', '#ff1493', '#ffb6c1', '#ff4757', '#ff6b81',
    '#ff9ff3', '#feca57', '#ff6348', '#ff7979', '#e056a0',
    '#fd79a8', '#f8a5c2', '#ffda79', '#ff7675'
  ];
  const shapes = ['circle', 'square'];

  for (let i = 0; i < 80; i++) {
    const confetti = document.createElement('div');
    confetti.className = 'confetti-piece';
    confetti.style.left = Math.random() * 100 + '%';
    confetti.style.top = -(Math.random() * 20 + 10) + 'px';
    confetti.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)];
    confetti.style.width = (Math.random() * 10 + 6) + 'px';
    confetti.style.height = (Math.random() * 10 + 6) + 'px';
    confetti.style.animationDuration = (Math.random() * 2 + 2.5) + 's';
    confetti.style.animationDelay = Math.random() * 0.8 + 's';
    if (shapes[Math.floor(Math.random() * 2)] === 'circle') {
      confetti.style.borderRadius = '50%';
    }
    document.body.appendChild(confetti);

    // 动画结束后清理
    const totalDuration = parseFloat(confetti.style.animationDuration) + parseFloat(confetti.style.animationDelay);
    setTimeout(() => {
      confetti.remove();
    }, totalDuration * 1000 + 200);
  }
}

// ============ 震动动画 ============
function shakeElement(el) {
  el.style.animation = 'shake 0.5s ease';
  el.style.borderColor = '#ff4757';
  setTimeout(() => {
    el.style.animation = '';
    el.style.borderColor = '';
  }, 500);
}

// 震动关键帧动态注入
const shakeStyle = document.createElement('style');
shakeStyle.textContent = `
  @keyframes shake {
    0%, 100% { transform: translateX(0); }
    20% { transform: translateX(-8px); }
    40% { transform: translateX(8px); }
    60% { transform: translateX(-5px); }
    80% { transform: translateX(5px); }
  }
`;
document.head.appendChild(shakeStyle);

// ============ 重置 ============
function handleReset() {
  // 隐藏信息区域
  hiddenMessage.classList.remove('visible');
  
  // 显示按钮
  loveBtn.style.display = 'inline-block';
  
  // 重置输入
  nameInput.value = '';
  nameInput.focus();
  
  // 重置隐藏信息
  responseName.textContent = '亲爱的';
  responseMessage.textContent = '我也好喜欢你！';
  
  // 滚动回顶部
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// ============ 启动 ============
document.addEventListener('DOMContentLoaded', init);
