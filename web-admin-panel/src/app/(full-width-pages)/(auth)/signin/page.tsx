import SignInForm from "@/components/auth/SignInForm";
import { Metadata } from "next";

export const metadata: Metadata = {
  title: "Admin Panel Dyslexia App",
  description: "This is Admin Panel Dyslexia App",
};

export default function SignIn() {
  return <SignInForm />;
}
