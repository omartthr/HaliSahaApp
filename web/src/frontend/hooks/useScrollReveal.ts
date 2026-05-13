"use client";

import { useEffect } from "react";

/**
 * useScrollReveal
 *
 * Sayfadaki tüm `.reveal` sınıflı elementleri izler.
 * Viewport'a girince `.visible` sınıfı eklenir → CSS animasyonu tetiklenir.
 * Sayfa kaydırıldıkça yeni giren elementler de animasyonla belirir.
 */
export function useScrollReveal() {
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("visible");
            // Bir kere tetiklendi mi? Sonrasında izlemeye gerek yok
            observer.unobserve(entry.target);
          }
        });
      },
      {
        threshold: 0.12,      // %12 göründüğünde tetikle
        rootMargin: "0px 0px -40px 0px", // Biraz erken tetikle
      }
    );

    // Mevcut .reveal elemanlarını observe et
    const attachObserver = () => {
      document.querySelectorAll(".reveal:not(.visible)").forEach((el) => {
        observer.observe(el);
      });
    };

    attachObserver();

    // DOM değişikliklerini izle (dinamik eklenen kartlar için)
    const mutationObserver = new MutationObserver(attachObserver);
    mutationObserver.observe(document.body, {
      childList: true,
      subtree: true,
    });

    return () => {
      observer.disconnect();
      mutationObserver.disconnect();
    };
  }, []);
}
