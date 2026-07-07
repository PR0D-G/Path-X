let currentSlide = 1;
const totalSlides = document.querySelectorAll('.slide').length;

function showSlide(n) {
    const slides = document.querySelectorAll('.slide');
    if (n > totalSlides) currentSlide = 1;
    if (n < 1) currentSlide = totalSlides;

    slides.forEach(slide => {
        slide.classList.remove('active');
    });

    document.getElementById(`slide-${currentSlide}`).classList.add('active');
    updateProgress();
}

function nextSlide() {
    currentSlide++;
    showSlide(currentSlide);
}

function prevSlide() {
    currentSlide--;
    showSlide(currentSlide);
}

function updateProgress() {
    const progress = (currentSlide / totalSlides) * 100;
    document.getElementById('progress-bar').style.width = `${progress}%`;
}

// Keyboard Navigation
document.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowRight' || e.key === ' ') {
        nextSlide();
    } else if (e.key === 'ArrowLeft') {
        prevSlide();
    }
});

// Initialize
updateProgress();
