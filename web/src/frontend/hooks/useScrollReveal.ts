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
        threshold: 0.12,
        rootMargin: "0px 0px -40px 0px",
      }
    );

    const attachObserver = () => {
      document.querySelectorAll(".reveal:not(.visible)").forEach((el) => {
        observer.observe(el);
      });
    };

    attachObserver();

    // DOM değişikliklerini izle — debounce ile gereksiz tarama engellenir
    let debounceTimer: ReturnType<typeof setTimeout>;
    const mutationObserver = new MutationObserver((mutations) => {
      // Sadece yeni node eklenmişse tarama yap (attribute değişimlerini atla)
      const hasAddedNodes = mutations.some(m => m.addedNodes.length > 0);
      if (!hasAddedNodes) return;

      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(attachObserver, 300);
    });
    mutationObserver.observe(document.body, {
      childList: true,
      subtree: true,
    });

    return () => {
      clearTimeout(debounceTimer);
      observer.disconnect();
      mutationObserver.disconnect();
    };
  }, []);
}
