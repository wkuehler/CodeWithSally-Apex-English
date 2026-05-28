import { Input } from "@/components/ui";
import { useState, Button } from 'react';

export default function Contact() {

    const [name, setName] = useState('');
    const [email, setEmail] = useState('');
    const [message, setMessage] = useState('');


  return (
    <div className="max-w-xl mx-auto px-4 py-12">
      <h1 className="text-4xl font-bold text-gray-900 mb-2 text-center">Contact Us</h1>
      <p className="text-gray-600 text-center mb-8">
        Have a question? Drop us a note.
      </p>

      <form className="flex flex-col gap-4">
        <div>
          <label htmlFor="name" className="block text-sm font-medium mb-1">Name</label>
          <Input id="name" 
          value={name}
          onChange={(e) => setName(e.target.value)}
          />
          <p>Current value: {name}</p>
        </div>

         <div>
          <label htmlFor="email" className="block text-sm font-medium mb-1">Email</label>
          <Input id="email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
        </div>
        <p>Current value: {email}</p>

        <div>
          <label htmlFor="message" className="block text-sm font-medium mb-1">Message</label>
          <textarea
            id="message"
            rows={4}
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            className="w-full border rounded-lg px-2.5 py-2 text-sm"
          />
        </div>

        <p>Current value: {message}</p>
        
        

      </form>
    </div>
  );
}