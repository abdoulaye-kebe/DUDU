// DUDU Website - Scripts principaux

document.addEventListener('DOMContentLoaded', function() {
    console.log('🚀 main.js chargé');
    
    // Menu Hamburger
    const hamburger = document.getElementById('mainHamburger');
    const navMenu = document.getElementById('mainNavMenu');
    
    console.log('🍔 Hamburger:', hamburger);
    console.log('📋 Menu:', navMenu);
    
    if (hamburger && navMenu) {
        hamburger.addEventListener('click', function() {
            console.log('🖱️ Clic sur hamburger détecté!');
            
            // Toggle la classe active
            hamburger.classList.toggle('active');
            navMenu.classList.toggle('active');
            
            const isActive = navMenu.classList.contains('active');
            console.log('✅ Menu actif:', isActive);
            console.log('📊 Classes du menu:', navMenu.className);
            console.log('📊 Classes du hamburger:', hamburger.className);
            
            // Logs CSS détaillés
            const styles = window.getComputedStyle(navMenu);
            console.log('🎨 CSS appliqué au menu:');
            console.log('  - display:', styles.display);
            console.log('  - position:', styles.position);
            console.log('  - right:', styles.right);
            console.log('  - top:', styles.top);
            console.log('  - width:', styles.width);
            console.log('  - height:', styles.height);
            console.log('  - background:', styles.background);
            console.log('  - z-index:', styles.zIndex);
            console.log('  - visibility:', styles.visibility);
            console.log('  - opacity:', styles.opacity);
        });
        
        // Fermer le menu quand on clique sur un lien
        const menuLinks = navMenu.querySelectorAll('a');
        console.log('🔗 Nombre de liens:', menuLinks.length);
        
        menuLinks.forEach(link => {
            link.addEventListener('click', function() {
                console.log('🔗 Clic sur lien:', this.textContent);
                hamburger.classList.remove('active');
                navMenu.classList.remove('active');
                console.log('❌ Menu fermé');
            });
        });
        
        console.log('✅ Menu hamburger initialisé avec succès');
    } else {
        console.error('❌ ERREUR: Hamburger ou NavMenu introuvable!');
        console.error('Hamburger ID:', hamburger ? 'trouvé' : 'MANQUANT');
        console.error('NavMenu ID:', navMenu ? 'trouvé' : 'MANQUANT');
    }
    
    // Navbar scroll effect
    window.addEventListener('scroll', function() {
        const navbar = document.querySelector('.navbar');
        if (navbar) {
            if (window.scrollY > 50) {
                navbar.classList.add('scrolled');
            } else {
                navbar.classList.remove('scrolled');
            }
        }
    });

    // Fade in animation on scroll (sans cacher le hero au chargement)
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);

    document.querySelectorAll('.fade-in-up').forEach(el => {
        // Ne pas masquer le contenu du hero : visible dès le chargement
        if (el.closest('.hero')) {
            el.style.opacity = '1';
            el.style.transform = 'translateY(0)';
            el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
            return;
        }
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
});
