"use client";

import { useRef, useEffect, ReactNode } from 'react';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

if (typeof window !== 'undefined') {
  gsap.registerPlugin(ScrollTrigger);
}

interface FadeContentProps {
  children: ReactNode;
  container?: any;
  blur?: boolean;
  duration?: number;
  ease?: string;
  delay?: number;
  threshold?: number;
  initialOpacity?: number;
  disappearAfter?: number;
  disappearDuration?: number;
  disappearEase?: string;
  onComplete?: () => void;
  onDisappearanceComplete?: () => void;
  className?: string;
  style?: React.CSSProperties;
  [key: string]: any;
}

const FadeContent = ({
  children,
  container,
  blur = false,
  duration = 1000,
  ease = 'power2.out',
  delay = 0,
  threshold = 0.1,
  initialOpacity = 0,
  disappearAfter = 0,
  disappearDuration = 0.5,
  disappearEase = 'power2.in',
  onComplete,
  onDisappearanceComplete,
  className = '',
  style,
  ...props
}: FadeContentProps) => {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    let scrollerTarget = container || document.getElementById('root');
    if (typeof scrollerTarget === 'string') {
      scrollerTarget = document.querySelector(scrollerTarget);
    }

    const startPct = (1 - threshold) * 100;
    const getSeconds = (val: number | string) => (typeof val === 'number' ? val / 1000 : val);

    gsap.set(el, {
      autoAlpha: initialOpacity,
      filter: blur ? 'blur(10px)' : 'blur(0px)',
      y: 20, // Add a little jump
      willChange: 'opacity, filter, transform'
    });

    const tl = gsap.timeline({
      paused: true,
      delay: typeof delay === 'number' ? delay / 1000 : 0,
      onComplete: () => {
        if (onComplete) onComplete();
        if (disappearAfter > 0) {
          gsap.to(el, {
            autoAlpha: initialOpacity,
            filter: blur ? 'blur(10px)' : 'blur(0px)',
            y: 20,
            delay: typeof disappearAfter === 'number' ? disappearAfter / 1000 : 0,
            duration: typeof disappearDuration === 'number' ? disappearDuration / 1000 : 0.5,
            ease: disappearEase as any,
            onComplete: () => onDisappearanceComplete?.()
          });
        }
      }
    });

    tl.to(el, {
      autoAlpha: 1,
      filter: 'blur(0px)',
      y: 0,
      duration: typeof duration === 'number' ? duration / 1000 : 1,
      ease: ease as any
    });

    const trigger = ScrollTrigger.create({
      trigger: el,
      start: `top ${startPct}%`,
      scroller: scrollerTarget || window,
      onEnter: () => tl.play()
    });

    return () => {
      trigger.kill();
      tl.kill();
    };
  }, [
    blur,
    duration,
    ease,
    delay,
    threshold,
    initialOpacity,
    disappearAfter,
    disappearDuration,
    disappearEase,
    onComplete,
    onDisappearanceComplete,
    container
  ]);

  return (
    <div
      ref={ref}
      className={className}
      style={{
        ...style
      }}
      {...props}
    >
      {children}
    </div>
  );
};

export default FadeContent;
