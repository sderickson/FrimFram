describe 'storage', ->
  FrimFram.storage.prefix = '-test-storage-'
  
  afterEach ->
    FrimFram.storage.clear()
  
  describe '.save(key, value) and .load(key)', ->
    it 'is an interface for storing and fetching JSON data', ->
      expect(FrimFram.storage.load('key')).toBeNull()
      something = { 1:2, test: ['a','b','c'] }
      FrimFram.storage.save('key', something)
      expect(_.isEqual(something, FrimFram.storage.load('key')))
      
  describe '.remove(key)', ->
    it 'clears a single key from the store', ->
      FrimFram.storage.save('key', 1)
      expect(FrimFram.storage.load('key')).toBe(1)
      FrimFram.storage.remove('key')
      expect(FrimFram.storage.load('key')).toBeNull()
      
  describe '.clear()', ->
    it 'removes all values in localStorage that were saved through the storage interface', ->
      expect(FrimFram.storage.load('key')).toBeNull()
      FrimFram.storage.save('key', 1)
      localStorage.setItem('key', 'test')
      expect(FrimFram.storage.load('key')).toBe(1)
      FrimFram.storage.clear()
      expect(FrimFram.storage.load('key')).toBeNull()
      expect(localStorage.getItem('key')).toBe('test')
      