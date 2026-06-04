declare module "iyzipay" {
  interface IyzipayConfig {
    apiKey: string;
    secretKey: string;
    uri: string;
  }

  type Callback<T> = (err: Error | null, result: T) => void;

  interface CheckoutFormInitializeResult {
    status: string;
    token: string;
    paymentPageUrl: string;
    errorMessage?: string;
    conversationId?: string;
  }

  interface CheckoutFormRetrieveResult {
    status: string;
    paymentStatus?: string;
    paymentId?: string;
    conversationId?: string;
    errorMessage?: string;
  }

  interface RefundResult {
    status: string;
    paymentId?: string;
    errorMessage?: string;
  }

  class Iyzipay {
    constructor(config: IyzipayConfig);
    checkoutFormInitialize: {
      create(request: Record<string, unknown>, callback: Callback<CheckoutFormInitializeResult>): void;
    };
    checkoutForm: {
      retrieve(request: Record<string, unknown>, callback: Callback<CheckoutFormRetrieveResult>): void;
    };
    refund: {
      create(request: Record<string, unknown>, callback: Callback<RefundResult>): void;
    };
    static LOCALE: { TR: string; EN: string };
    static CURRENCY: { TRY: string; USD: string; EUR: string };
    static PAYMENT_GROUP: { PRODUCT: string; LISTING: string; SUBSCRIPTION: string };
    static BASKET_ITEM_TYPE: { PHYSICAL: string; VIRTUAL: string };
  }

  export = Iyzipay;
}
