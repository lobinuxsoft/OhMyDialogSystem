/**
 * OhMyDialogSystem - Neural Network Background Effect
 * Subtle animated neural network visualization
 */

(function() {
  const canvas = document.getElementById('neural-bg');
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  let width, height;
  let nodes = [];
  let animationId;

  // Configuration
  const config = {
    nodeCount: 50,
    nodeRadius: 2,
    connectionDistance: 150,
    nodeSpeed: 0.3,
    colors: {
      node: 'rgba(0, 212, 255, 0.6)',
      nodeGlow: 'rgba(0, 212, 255, 0.3)',
      connection: 'rgba(168, 85, 247, 0.15)',
      connectionActive: 'rgba(0, 212, 255, 0.25)'
    }
  };

  // Node class
  class Node {
    constructor() {
      this.x = Math.random() * width;
      this.y = Math.random() * height;
      this.vx = (Math.random() - 0.5) * config.nodeSpeed;
      this.vy = (Math.random() - 0.5) * config.nodeSpeed;
      this.radius = config.nodeRadius + Math.random() * 2;
      this.pulsePhase = Math.random() * Math.PI * 2;
    }

    update() {
      this.x += this.vx;
      this.y += this.vy;
      this.pulsePhase += 0.02;

      // Bounce off edges
      if (this.x < 0 || this.x > width) this.vx *= -1;
      if (this.y < 0 || this.y > height) this.vy *= -1;

      // Keep in bounds
      this.x = Math.max(0, Math.min(width, this.x));
      this.y = Math.max(0, Math.min(height, this.y));
    }

    draw() {
      const pulse = Math.sin(this.pulsePhase) * 0.5 + 0.5;
      const glowRadius = this.radius + pulse * 4;

      // Glow
      const gradient = ctx.createRadialGradient(
        this.x, this.y, 0,
        this.x, this.y, glowRadius
      );
      gradient.addColorStop(0, config.colors.node);
      gradient.addColorStop(1, 'transparent');

      ctx.beginPath();
      ctx.arc(this.x, this.y, glowRadius, 0, Math.PI * 2);
      ctx.fillStyle = gradient;
      ctx.fill();

      // Core
      ctx.beginPath();
      ctx.arc(this.x, this.y, this.radius, 0, Math.PI * 2);
      ctx.fillStyle = config.colors.node;
      ctx.fill();
    }
  }

  // Initialize
  function init() {
    resize();
    nodes = [];
    for (let i = 0; i < config.nodeCount; i++) {
      nodes.push(new Node());
    }
  }

  // Resize handler
  function resize() {
    width = canvas.width = window.innerWidth;
    height = canvas.height = window.innerHeight;
  }

  // Draw connections between nearby nodes
  function drawConnections() {
    for (let i = 0; i < nodes.length; i++) {
      for (let j = i + 1; j < nodes.length; j++) {
        const dx = nodes[i].x - nodes[j].x;
        const dy = nodes[i].y - nodes[j].y;
        const distance = Math.sqrt(dx * dx + dy * dy);

        if (distance < config.connectionDistance) {
          const opacity = 1 - (distance / config.connectionDistance);

          ctx.beginPath();
          ctx.moveTo(nodes[i].x, nodes[i].y);
          ctx.lineTo(nodes[j].x, nodes[j].y);

          // Gradient line
          const gradient = ctx.createLinearGradient(
            nodes[i].x, nodes[i].y,
            nodes[j].x, nodes[j].y
          );
          gradient.addColorStop(0, `rgba(0, 212, 255, ${opacity * 0.2})`);
          gradient.addColorStop(0.5, `rgba(168, 85, 247, ${opacity * 0.15})`);
          gradient.addColorStop(1, `rgba(0, 212, 255, ${opacity * 0.2})`);

          ctx.strokeStyle = gradient;
          ctx.lineWidth = opacity * 1.5;
          ctx.stroke();
        }
      }
    }
  }

  // Animation loop
  function animate() {
    ctx.clearRect(0, 0, width, height);

    // Draw connections first (behind nodes)
    drawConnections();

    // Update and draw nodes
    nodes.forEach(node => {
      node.update();
      node.draw();
    });

    animationId = requestAnimationFrame(animate);
  }

  // Event listeners
  window.addEventListener('resize', () => {
    resize();
  });

  // Mouse interaction - attract nearby nodes
  let mouseX = 0, mouseY = 0;
  let mouseActive = false;

  document.addEventListener('mousemove', (e) => {
    mouseX = e.clientX;
    mouseY = e.clientY;
    mouseActive = true;

    // Subtle attraction to mouse
    nodes.forEach(node => {
      const dx = mouseX - node.x;
      const dy = mouseY - node.y;
      const distance = Math.sqrt(dx * dx + dy * dy);

      if (distance < 200 && distance > 0) {
        const force = 0.0005;
        node.vx += (dx / distance) * force;
        node.vy += (dy / distance) * force;

        // Limit velocity
        const maxSpeed = config.nodeSpeed * 2;
        const speed = Math.sqrt(node.vx * node.vx + node.vy * node.vy);
        if (speed > maxSpeed) {
          node.vx = (node.vx / speed) * maxSpeed;
          node.vy = (node.vy / speed) * maxSpeed;
        }
      }
    });
  });

  document.addEventListener('mouseleave', () => {
    mouseActive = false;
  });

  // Visibility API - pause when tab is hidden
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
      cancelAnimationFrame(animationId);
    } else {
      animate();
    }
  });

  // Start
  init();
  animate();
})();
