const request = require('supertest')
const db      = require('../db')
const BASE    = process.env.BASE_URL || 'http://localhost:3000'

beforeAll(async () => {
  await db.query('DELETE FROM users')
})

describe('signing up', () => {
  test('accepts a valid new user', async () => {
    const res = await request(BASE)
      .post('/register')
      .send({
        email: 'oziel@utrgv.edu',
        password: 'password123',
        parking_zone: 2
      })
    expect(res.status).toBe(201)
    expect(res.body).toEqual({message: 'User registered successfully'})
  })

  test('wont let you sign up with the same email twice', async () => {
    const res = await request(BASE)
      .post('/register')
      .send({
        email: 'oziel@utrgv.edu',
        password: 'password123',
        parking_zone: 2
      })
    expect(res.status).toBe(400)
    expect(res.body.error).toBe('Email already registered')
  })
})

describe('Signing In', () => {
  test('lets you log in with correct credentials', async () => {
    const res = await request(BASE)
      .post('/login')
      .send({email: 'oziel@utrgv.edu', password: 'password123'})
    expect(res.status).toBe(200)
    expect(res.body).toMatchObject({
      email: 'oziel@utrgv.edu',
      parking_zone: 2,
      role: 'user'
    })
    expect(typeof res.body.id).toBe('number')
  })

  test('rejects a wrong password', async () => {
    const res = await request(BASE)
      .post('/login')
      .send({email: 'oziel@utrgv.edu', password: 'wrongpass'})
    expect(res.status).toBe(401)
    expect(res.body.error).toBe('Invalid email or password')
  })
})

describe('Changing Your Password', () => {
  test('lets you update your password when you know the old one', async () => {
    const change = await request(BASE)
      .post('/change-password')
      .send({
        email:'oziel@utrgv.edu',
        oldPassword:'password123',
        newPassword: 'newPassword456'
      })
    expect(change.status).toBe(200)
    expect(change.body.message).toBe('Password changed successfully')

    const login = await request(BASE)
      .post('/login')
      .send({email: 'oziel@utrgv.edu', password: 'newPassword456'})
    expect(login.status).toBe(200)
  })

  test('lets you reset your password if you forgot the old one', async () => {
    const reset = await request(BASE)
      .post('/change-password')
      .send({
        email: 'oziel@utrgv.edu',
        newPassword: 'finalPass789'
      })
    expect(reset.status).toBe(200)
    expect(reset.body.message).toBe('Password reset successfully')

    const login = await request(BASE)
      .post('/login')
      .send({email: 'oziel@utrgv.edu', password: 'finalPass789'})
    expect(login.status).toBe(200)
  })
})

describe('Viewing and Removing Users', () => {
  test('shows a list of users', async () => {
    const res = await request(BASE).get('/users')
    expect(res.status).toBe(200)
    expect(Array.isArray(res.body)).toBe(true)
    expect(res.body.some(u => u.email === 'oziel@utrgv.edu')).toBe(true)
  })

  test('lets you delete a user and removes them from the list', async () => {
    const users = await request(BASE).get('/users')
    const target = users.body.find(u => u.email === 'oziel@utrgv.edu')
    expect(target).toBeDefined()

    const deleted = await request(BASE).delete(`/users/${target.id}`)
    expect(deleted.status).toBe(200)
    expect(deleted.body.message).toBe('User deleted successfully')

    const after = await request(BASE).get('/users')
    expect(after.body.find(u => u.id === target.id)).toBeUndefined()
  })
})

describe('Claiming & Releasing Parking Spots', () => {
  test('lets you claim a spot if its free', async () => {
    const res = await request(BASE)
      .post('/parking/claim')
      .send({ spot_id: 'spot_1', user_id: 'user_1'})
    expect(res.status).toBe(200)
    expect(res.body).toEqual({success: true, spot_id: 'spot_1'})
  })

  test('lets you unclaim a spot you own', async () => {
    await request(BASE)
      .post('/parking/claim')
      .send({spot_id: 'spot_2', user_id: 'user_2'})

    const res = await request(BASE)
      .post('/parking/unclaim')
      .send({spot_id: 'spot_2', user_id: 'user_2'})
    expect(res.status).toBe(200)
    expect(res.body).toEqual({success: true, spot_id: 'spot_2'})
  })
})